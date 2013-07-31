module ChefSSL
  class Client
    class CertSaveFailed < StandardError; end

    class IssuedCertificate

      DATABAG = "certificates"

      def initialize(req, cert, ca=nil)
        @ca = ca
        @req = req
        @cert = cert
      end

      def to_pem
        @cert.to_pem
      end

      def sha1_fingerprint
        @cert.sha1_fingerprint
      end

      def subject
        @cert.subject.to_s
      end

      def issuer
        @cert.issuer.to_s
      end

      def not_after
        @cert.not_after
      end

      def save!
        begin
          Spice.create_data_bag(DATABAG)
        rescue Spice::Error::Conflict
          nil
        end

        data = {
          :name => DATABAG,
          :id => @req.id,
          :dn => @req.subject,
          :ca => @req.ca,
          :csr => @req.to_pem,
          :key => @req.key,
          :type => @req.type,
          :date => Time.now.to_s,
          :not_after => @cert.not_after,
          :not_before => @cert.not_before,
          :host => @req.host,
          :certificate => @cert.to_pem
        }
        unless @ca.nil?
          data[:cacert] = @ca.certificate.to_pem
        end

        begin
          ret = Spice.create_data_bag_item(DATABAG, data)
        rescue Spice::Error::Conflict
          raise CertSaveFailed.new("Conflict - certificate data bag exists for #{@req.subject}, id #{@req.id}")
        rescue Spice::Error::ClientError => e
          raise CertSaveFailed.new(e.message)
        end
      end

    end
  end
end
