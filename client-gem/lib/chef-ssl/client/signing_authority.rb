module ChefSSL
  class Client
    class SigningAuthority

      def self.load(options)
        ca = EaSSL::CertificateAuthority.load(
          :ca_path => options[:path],
          :ca_password => options[:password]
          )
        self.new(ca)
      end

      def initialize(ca)
        @ca = ca
      end

      def dn
        @ca.certificate.subject.to_s
      end

      def sign(req)
        cert = @ca.create_certificate(req.csr, req.type, req.days)
        IssuedCertificate.new(req, cert, @ca)
      end

      def self.create(name, path, passphrase)
        config = {
          :ca_dir => path,
          :password => passphrase,
          :ca_rsa_key_length => 1024,
          :ca_cert_days => 3650,
          :name => name
        }
        config[:serial_file] = File.join(config[:ca_dir], 'serial.txt')
        config[:keypair_file] = File.join(config[:ca_dir], 'cakey.pem')
        config[:cert_file] = File.join(config[:ca_dir], 'cacert.pem')

        Dir.mkdir config[:ca_dir]
        Dir.mkdir File.join(config[:ca_dir], 'private'), 0700
        Dir.mkdir File.join(config[:ca_dir], 'newcerts')
        Dir.mkdir File.join(config[:ca_dir], 'crl')

        File.open config[:serial_file], 'w' do |f| f << '1' end

        keypair = OpenSSL::PKey::RSA.new config[:ca_rsa_key_length]

        cert = OpenSSL::X509::Certificate.new
        cert.subject = cert.issuer = config[:name]
        cert.not_before = Time.now
        cert.not_after = Time.now + config[:ca_cert_days] * 24 * 60 * 60
        cert.public_key = keypair.public_key
        cert.serial = 0x0
        cert.version = 2 # X509v3

        ef = OpenSSL::X509::ExtensionFactory.new
        ef.subject_certificate = cert
        ef.issuer_certificate = cert
        cert.extensions = [
          ef.create_extension("basicConstraints", "CA:TRUE", true),
          ef.create_extension("nsComment", "Ruby/OpenSSL/chef-ssl Generated Certificate"),
          ef.create_extension("subjectKeyIdentifier", "hash"),
          ef.create_extension("keyUsage", "cRLSign,keyCertSign", true),
        ]
        cert.add_extension ef.create_extension("authorityKeyIdentifier",
          "keyid:always,issuer:always")
        cert.sign keypair, OpenSSL::Digest::SHA1.new

        keypair_export = keypair.export OpenSSL::Cipher::DES.new(:EDE3, :CBC),
        config[:password]

        File.open config[:keypair_file], "w", 0400 do |fp|
          fp << keypair_export
        end

        File.open config[:cert_file], "w", 0644 do |f|
          f << cert.to_pem
        end
      end
    end
  end
end


