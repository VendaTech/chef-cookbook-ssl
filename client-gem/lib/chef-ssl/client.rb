require 'spice'
require 'eassl'
require 'json'
require 'openssl'
require 'digest/sha2'
require 'active_support/hash_with_indifferent_access'
require 'chef/knife'
require 'chef/config'
require 'chef/node'
require 'date'
require 'open3'
require 'fileutils'

require 'chef-ssl/client/version'
require 'chef-ssl/client/request'
require 'chef-ssl/client/signing_authority'
require 'chef-ssl/client/issued_certificate'

module ChefSSL
  class Client
    
    def initialize
      Chef::Knife.new.tap do |knife|
        # Set the log-level, knife style. This equals :error level
        Chef::Config[:verbosity] = knife.config[:verbosity] ||= 0
        knife.configure_chef
      end

      Spice.reset

      # avoid Spice issue if chef_server_url has a trailing slash.
      chef_server_url = Chef::Config.chef_server_url
      chef_server_url.gsub!(/\/$/, '')

      if Chef::Config.ssl_verify_mode == :verify_none
        verify_mode = OpenSSL::SSL::VERIFY_NONE
      else
        verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      Spice.setup do |s|
        s.server_url = chef_server_url
        s.client_name = Chef::Config.node_name
        s.client_key = Spice.read_key_file(File.expand_path(Chef::Config.client_key))
        s.connection_options = {
          :ssl => {
            :verify_mode => verify_mode,
            :client_cert => Chef::Config.ssl_client_cert,
            :client_key => Chef::Config.ssl_client_key,
            :ca_path => Chef::Config.ssl_ca_path,
            :ca_file => Chef::Config.ssl_ca_file,
          }
        }
      end
    end

    def self.load_authority(options)
      SigningAuthority.load(
        :path => options[:path],
        :password => options[:password]
      )
    end

    def ca_search(ca=nil)
      if ca
        nodes = Spice.nodes("csr_outbox_*_ca:#{ca}")
      else
        nodes = Spice.nodes("csr_outbox_*")
      end
      nodes.each do |node|
        next if node.normal['csr_outbox'].nil?
        node.normal['csr_outbox'].each do |id, data|
          next if data['csr'].nil? # XXX warn, raise?
          yield Request.new(node.name, data)
        end
      end
    end

    def common_name_search(name)
      name_sha = Digest::SHA256.new << name
      cert_id = name_sha.to_s
      nodes = Spice.nodes("csr_outbox_*_id:#{cert_id}")
      nodes.each do |node|
        node.normal['csr_outbox'].each do |id, data|
          next unless data['id'] == cert_id
          next if data['csr'].nil? # XXX warn, raise?
          yield Request.new(node.name, data)
        end
      end
    end

    # Revoke a certificate for the given hostname. This doesn't actually quite revoke
    # it, but instead moves the cert from the _certificates_ databag and moves it
    # to the _revoked_certificates_ databag, adding trhee attributes, namely _revoked_, 
    # _revoked_date_ and _serial_. _revoked_ is set to false, to be later changed when the cert is
    # really revoked by the gencrl command. _serial_ can be used to generate a list of revoked
    # ceritificates such as for OpenVPN >= 2.3.0
    #
    # This seems like a hack but allows for revocation by automated scripts, without 
    # requiring the CA passphrase. 
    #
    def revoke_certificate(hostname)
      now = DateTime.now()
      revoke_params = {
        "revoked" => false,
        "revoked_date" => now.strftime("%Y-%m-%d %H:%M:%S %z"),
        "serial" => nil
      }
      num_revoked = 0

      #ensure the revoked data bag exists
      revoked_data_bag = get_or_create_databag(IssuedCertificate::REVOKED_DATABAG)

      #spice has a weird problem with looping through data bag items so we do it this way.
      raw_items = Spice.get("/data/" + IssuedCertificate::DATABAG)
      raw_items.each do |raw_item|
        cert_item = Spice.data_bag_item(IssuedCertificate::DATABAG, raw_item[0])
        if cert_item['host'] == hostname
          orig_attrs = cert_item.attrs.clone
          begin
            #try create the cert in the revoked data bag
            revoke_item = Spice.create_data_bag_item(IssuedCertificate::REVOKED_DATABAG, cert_item.attrs)
          rescue Spice::Error::Conflict
            #already exists, so overwrite it. Likely the cert for the CN has been revoked previously, then a 
            #new cert signed for that CN, and now we're revoking a new cert for the same CN. If revoked:true, it has been
            #properly revoked already, move it. Else fail because it needs to be properly revoked.
            revoke_item = Spice.data_bag_item(IssuedCertificate::REVOKED_DATABAG, cert_item['id'])
            if revoke_item['revoked'] == false
              raise "Certificate for host '" + hostname + "' has been marked as revoked but not properly revoked yet. Run 'chef-ssl gencrl' first, then rerun this command."
            else
              new_id = move_revoked_cert(revoke_item)
              say "A certificate for hostname '" + hostname + "' has already been revoked, moved it to a new id: " + new_id
	      #create it up again because we deleted it in move_revoked_cert()
              revoke_item = Spice.create_data_bag_item(IssuedCertificate::REVOKED_DATABAG, orig_attrs)
            end
          end

          #get serial 
          revoke_params['serial'] = get_serial(revoke_item['certificate'])

          #add our new params and update
          revoke_item.attrs.merge!(revoke_params)
          Spice.update_data_bag_item(IssuedCertificate::REVOKED_DATABAG, revoke_item['id'], revoke_item.attrs)

          #finally delete the item we're looking at.
          Spice.delete_data_bag_item(IssuedCertificate::DATABAG, cert_item['id'])

          num_revoked += 1
        end
      end
      say "Revoked " + num_revoked.to_s + " certificates for '" + hostname + "'."
    end

    # private helper to move a certificate to a new id in the revoked certificate data bag
    def move_revoked_cert(cert)
      #generate new id based on CN, date issued, and date revoked to get a new unique id
      old_id = cert['id']
      id_sha = Digest::SHA256.new << cert['dn'] << cert['date'] << cert['revoked_date']
      new_id = id_sha.to_s
      params = {
        "id" => new_id
      }
      new_attrs = cert.attrs.clone
      new_attrs.merge!(params)
      Spice.create_data_bag_item(IssuedCertificate::REVOKED_DATABAG, new_attrs)
      Spice.delete_data_bag_item(IssuedCertificate::REVOKED_DATABAG, old_id)
      return new_id
    end

    # private helper to get serial from a certificate
    def get_serial(certificate_string)
      certificate = OpenSSL::X509::Certificate.new(certificate_string)
      return certificate.serial.to_s
    end
    
    #private helper to get a data bag or create it if needed 
    def get_or_create_databag(name)
      begin
        data_bag = Spice.data_bag(name)
      rescue Spice::Error::NotFound
        data_bag = Spice.create_data_bag(name)
      end
      return data_bag
    end
  
    #get the hash of the CA that signed this CRL
    #command: openssl crl -in crl.pem -hash -noout 
    def get_crl_hash(crlfilename)
      cmd = 'openssl crl -in ' + crlfilename + ' -hash -noout'
      hash = %x[ #{cmd} ]
      hash.delete!("\n")
      return hash
    end

 
    #private helper function, takes a CRL file (pem format) and uploads it to the certificate_revocation_list data bag
    #using the CA 
    def upload_crl(crlfilename, authority, ca_name) 
      now = DateTime.now()
      ca_hash = get_crl_hash(crlfilename)
      crl_data_bag = get_or_create_databag(SigningAuthority::CRL_DATABAG)
      #ID must match: /^[\-[:alnum:]_]+$/ so ID is hash of the dn
      name_sha = Digest::SHA256.new << authority.dn
      crl_id = name_sha.to_s
      crl_params = {
        "id" => crl_id, 
        "crl" => IO.read(crlfilename),
        "dn" => authority.dn,
        "ca_name" => ca_name,
        "hash" => ca_hash,
        "updated_date" => now.strftime("%Y-%m-%d %H:%M:%S %z")
      }
      begin
        #try create the cert in the revoked data bag
        crl_item = Spice.create_data_bag_item(SigningAuthority::CRL_DATABAG, crl_params)
      rescue Spice::Error::Conflict
        #already exists, update it
        crl_item = Spice.data_bag_item(SigningAuthority::CRL_DATABAG, crl_id)
        crl_item.attrs.merge!(crl_params)
        Spice.update_data_bag_item(SigningAuthority::CRL_DATABAG, crl_id, crl_item.attrs)
      end 
    end
    
    # Generate a CRL, but first really revoke any certificates in the 
    # _revoked_certificates_ data bag that have _revoked_ set to false. Both of these
    # operations require the passphrase. Logic is thus:
    #
    # * For each data bag item with revoked:false
    #   * grab cert and write to file (for openssl)
    #   * run _openssl ca -revoke_ against the file
    #   * update data bag item with revoked:true and the revoked_date_v2 date.
    # * Generate the new CRL file regardless if we revoked anything or not. This is on purpose.
    # * Upload the CRL to the certificate_revocation_list data bag
    #
    # The SigningAuthority is passed here but not actually used except for getting the 
    # DN from the key. Since there is no OpenSSL API to revoke the cert or generate a CRL
    # we have to # call out to openssl proper to do so.
    def generate_crl(passphrase, capath, caconfig, crlfilename, revoked_path, authority, ca_name)
      #look through the revoked data bag and get items that have revoked:false set
      num_revoked = 0

      now = DateTime.now()
      revoked_attributes = {
        "revoked" => true,
        "revoked_date_v2" => now.strftime("%Y-%m-%d %H:%M:%S %z")
      }

      #loop through data bag items, using get and then retrieval due to spice issue
      raw_items = Spice.get("/data/" + IssuedCertificate::REVOKED_DATABAG)
      raw_items.each do |raw_item|
        revoked_item = Spice.data_bag_item(IssuedCertificate::REVOKED_DATABAG, raw_item[0])
        if revoked_item['revoked'] != true
          #1. Write out cert into file from 'certificate' attribute
          cert_file = write_cert_to_file(revoked_item, revoked_path)

          #2. Run openssl against file.
          #Example: openssl ca -revoke cert.pem -config testca.conf  -key test123
          exec_openssl_ca(['-revoke', cert_file, '-config', caconfig, '-key', passphrase])

          #4. Update the data bag item
          revoked_item.attrs.merge!(revoked_attributes)
          Spice.update_data_bag_item(IssuedCertificate::REVOKED_DATABAG, revoked_item['id'], revoked_item.attrs)
          num_revoked += 1
        end
      end

      #generate CRL file
      #Example: openssl ca -gencrl -config conf/testca.conf -key testing -out crl.pem
      exec_openssl_ca(['-gencrl', '-config', caconfig, '-key', passphrase, '-out', crlfilename])
      say "Generated CRL '" + crlfilename + "'."

      #upload CRL to data bag
      upload_crl(crlfilename, authority, ca_name)
      say "Uploaded CRL to chef."
    end
      
    # Private helper method used to write a certificate to a file.
    def write_cert_to_file(revoked_item, revoked_path)
      dirname = File.dirname(revoked_path)
      unless File.directory?(revoked_path)
        FileUtils.mkdir_p(revoked_path)
      end
      filename = revoked_path + "/" + revoked_item['host'] + ".pem"
      File.open(filename, 'w') { |file| file.write(revoked_item['certificate']) }
      return filename
    end

    # Private helper method to run "openssl ca" commands. 
   def exec_openssl_ca(args)
      #args is an array of options 
      cmd = "openssl ca " + args.join(" ")
      status = 0
      err = ''
      out = ''
      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        stderr.each { |line| err += line }
        stdout.each { |line| out += line }
        status = wait_thr.value
      end
      if status.exitstatus != 0
        #something bad happened
        mssg = "Error running command '" + cmd + ": " 
        if not out.nil?
          mssg += out.to_s
        end
        if not err.nil?
          mssg += " " + err.to_s
        end
        raise mssg
      end
    end
  end
end

