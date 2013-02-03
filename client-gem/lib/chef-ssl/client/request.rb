module ChefSSL
  class Client
    class Request

      attr_reader :host, :csr, :type, :ca, :id, :name, :key, :days

      def initialize(host, data, csr=nil)
        @host = host
        @csr = csr || EaSSL::SigningRequest.new.load(data['csr'])
        @type = data['type']
        @ca = data['ca']
        @id = data['id']
        @name = data['name']
        @key = data['key']
        @days = data['days'] || (365 * 5)
      end

      def subject
        @csr.subject.to_s
      end

      def to_pem
        @csr.to_pem
      end

      def issue_certificate(cert_text)
        cert = EaSSL::Certificate.new({}).load(cert_text)
        IssuedCertificate.new(self, cert)
      end

      def self.create(key, type, options)
        name = EaSSL::CertificateName.new(options)
        csr  = EaSSL::SigningRequest.new(:name => name, :key => key)
        self.new('localhost', { 'type' => type }, csr)
      end
    end
  end
end
