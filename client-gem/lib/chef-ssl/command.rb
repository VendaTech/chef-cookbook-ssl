program :name, "chef-ssl"
program :version, ChefSSL::Client::VERSION
program :description, "Chef-automated SSL certificate signing tool"
program :help_formatter, :compact

default_command :help

command :issue do |c|
  c.syntax = "chef-ssl issue [options]"
  c.description = "Issue an ad hoc certificate"
  c.example "Issue cert for www.venda.com",
            "chef-ssl issue --ca-path ./myCA --dn /CN=foo --type server"

  c.option "--ca-path=STRING", String, "the path to the new CA"
  c.option "--dn=STRING", String, "the distinguished name for the new certificate"
  c.option "--type=STRING", String, "the type of certificate, client or server"

  c.action do |args, options|
    raise "CA path is required" unless options.ca_path
    raise "DN is required" unless options.dn
    raise "type is required" unless options.type

    begin
      dn = OpenSSL::X509::Name.parse(options.dn)
    rescue NoMethodError
      raise "--dn is required and must be a distinguished name"
    rescue TypeError
      raise "--dn is required and must be a distinguished name"
    rescue OpenSSL::X509::NameError => e
      raise "--dn must specify a valid DN: #{e.message}"
    end

    unless options.type == 'server' || options.type == 'client'
      raise "type must be server or client"
    end

    authority = ChefSSL::Client.load_authority(
      :password => ask("Enter CA passphrase:  ") { |q| q.echo = false },
      :path => options.ca_path
    )

    key = EaSSL::Key.new

    h = dn.to_a.reduce({}) { |h, elem| h[elem[0]] = elem[1]; h }
    name = {
      :city => h['L'],
      :state => h['ST'],
      :country => h['C'],
      :department => h['OU'],
      :common_name => h['CN'],
      :organization => h['O'],
      :email => h['emailAddress']
    }

    req = ChefSSL::Client::Request.create(key, options.type, name)
    cert = authority.sign(req)

    puts "#{'Key:'.cyan}"
    puts HighLine.color(key.private_key.to_s, :bright_black)
    puts
    puts "#{'Certificate:'.cyan} SHA1 Fingerprint=#{cert.sha1_fingerprint}"
    puts HighLine.color(cert.to_pem, :bright_black)
  end
end

command :makeca do |c|
  c.syntax = "chef-ssl makeca [options]"
  c.description = "Creates a new CA"
  c.example "Upload cert for CSR www.venda.com",
            "chef-ssl makeca --ca-name '/CN=My New CA' --ca-path ./newCA"

  c.option "--ca-path=STRING", String, "the path to the new CA"
  c.option "--ca-name=STRING", String, "the distinguished name of the new CA"

  c.action do |args, options|
    begin
      name = OpenSSL::X509::Name.parse(options.ca_name)
    rescue NoMethodError
      raise "--ca-name is required and must be a distinguished name"
    rescue TypeError
      raise "--ca-name is required and must be a distinguished name"
    rescue OpenSSL::X509::NameError => e
      raise "--ca-name must specify a valid DN: #{e.message}"
    end

    raise "CA path is required" unless options.ca_path
    raise "CA path must not already exist" if Dir.glob(options.ca_path).length > 0

    puts "#{'New CA DN'.cyan}: #{name.to_s}"
    puts

    passphrase = ask("Enter new CA passphrase:  ") { |q| q.echo = false }
    passphrase2 = ask("Re-enter new CA passphrase:  ") { |q| q.echo = false }
    raise "passphrases do not match" unless passphrase == passphrase2

    print "\n#{'Creating new CA'.cyan}: "
    ChefSSL::Client::SigningAuthority.create(name, options.ca_path, passphrase)
    puts "done"
  end
end

command :search do |c|
  c.syntax = "chef-ssl search [options]"
  c.description = "Searches for outstanding CSRs"
  c.example "Search for all CSRs awaiting signing by CA bob",
            "chef-ssl search --ca-name bob"

  c.option "--ca-name=STRING", String, "a name of a CA to limit the search by"

  c.action do |args, options|
    client = ChefSSL::Client.new

    puts "#{'Search CA'.cyan}: #{options.ca_name}" if options.ca_name

    client.ca_search(options.ca_name) do |req|
      puts
      puts "#{'     Node Hostname'.cyan}: #{req.host}"
      puts "#{'  Certificate Type'.cyan}: #{req.type.bold}"
      puts "#{'    Certificate DN'.cyan}: #{req.subject.bold}"
      puts "#{'      Requested CA'.cyan}: #{req.ca.bold}"
      puts "#{'Requested Validity'.cyan}: #{req.days.to_s.bold} days"
      puts
      puts HighLine.color(req.to_pem, :bright_black)
    end
  end
end

command :sign do |c|
  c.syntax = "chef-ssl sign [options]"
  c.description = "Search for the given CSR by name and provide a signed certificate"
  c.example "Provide signed cert for CSR www.venda.com",
            "chef-ssl --name www.venda.com"

  c.option "--name=STRING", String, "common name of the CSR to search for"

  c.action do |args, options|

    raise "--name is required" unless options.name

    client = ChefSSL::Client.new

    puts "#{'Search name'.cyan}: #{options.name}"

    client.common_name_search(options.name) do |req|
      puts
      puts "#{'     Node Hostname'.cyan}: #{req.host}"
      puts "#{'  Certificate Type'.cyan}: #{req.type.bold}"
      puts "#{'    Certificate DN'.cyan}: #{req.subject.bold}"
      puts "#{'      Requested CA'.cyan}: #{req.ca.bold}"
      puts "#{'Requested Validity'.cyan}: #{req.days.to_s.bold} days"
      puts
      puts HighLine.color(req.to_pem, :bright_black)

      cert = nil

      HighLine.new.choose do |menu|
        menu.layout = :one_line
        menu.prompt = "Sign this? "

        menu.choice :yes do
          cert_text = ask("Paste cert text") do |q|
            q.gather = ""
          end
          cert = req.issue_certificate(cert_text.join("\n"))
        end
        menu.choice :no do
          nil
        end
      end

      if cert
        puts "#{' Signed:'.cyan} SHA1 Fingerprint=#{cert.sha1_fingerprint}"
        puts "#{'Subject:'.cyan} #{cert.subject}"
        puts "#{' Issuer:'.cyan} #{cert.issuer}"
        puts HighLine.color(cert.to_pem, :bright_black)

        unless cert.subject == req.subject
          puts "#{'WARNING:'.red.bold} #{'Issued certificate DN does not match request DN!'.bold}"
        end

        HighLine.new.choose do |menu|
          menu.layout = :one_line
          menu.prompt = "Save certificate? "

          menu.choice :yes do
            begin
              cert.save!
              puts "Saved OK"
            rescue ChefSSL::Client::CertSaveFailed => e
              puts "Error saving: #{e.message}"
            end
          end
          menu.choice :no do
            nil
          end
        end
      end
    end
  end
end

command :autosign do |c|
  c.syntax = "chef-ssl autosign [options]"
  c.description = "Search for CSRs and sign them with the given CA"
  c.example "Sign with 'CA'",
            "chef-ssl --ca-path CA --ca-name autoCA"

  c.option "--ca-path=STRING", String, "the path to the signing CA"
  c.option "--ca-name=STRING", String, "the name of the signing CA"

  c.action do |args, options|

    raise "--ca-path is required" unless options.ca_path
    raise "--ca-name is required" unless options.ca_name

    authority = ChefSSL::Client.load_authority(
      :password => ask("Enter CA passphrase:  ") { |q| q.echo = false },
      :path => options.ca_path
    )

    client = ChefSSL::Client.new

    puts "#{'Search CA'.cyan}: #{options.ca_name}"

    client.ca_search(options.ca_name) do |req|
      puts
      puts "#{'     Node Hostname'.cyan}: #{req.host}"
      puts "#{'  Certificate Type'.cyan}: #{req.type.bold}"
      puts "#{'    Certificate DN'.cyan}: #{req.subject.bold}"
      puts "#{'      Requested CA'.cyan}: #{req.ca.bold}"
      puts "#{'Requested Validity'.cyan}: #{req.days.to_s.bold} days"
      puts
      puts HighLine.color(req.to_pem, :bright_black)

      HighLine.new.choose do |menu|
        menu.layout = :one_line
        menu.prompt = "#{'Sign with'.cyan}: #{HighLine.color(authority.dn, :bold)}\nSign this? "

        menu.choice :yes do
          cert = authority.sign(req)
          puts
          puts "#{'Signed:'.cyan} SHA1 Fingerprint=#{cert.sha1_fingerprint}"
          puts HighLine.color(cert.to_pem, :bright_black)
          begin
            cert.save!
            puts "Saved OK"
          rescue ChefSSL::Client::CertSaveFailed => e
            puts "Error saving: #{e.message}"
          end
        end

        menu.choice :no do
          nil
        end
      end
    end

    puts "All CSRs processed."
  end
end
