require 'spec_helper'

describe ChefSSL::Client::SigningAuthority do

  describe "using an existing CA" do

    before(:each) do
      path = File.expand_path('fixtures/ca', File.dirname(__FILE__))
      @sa = ChefSSL::Client::SigningAuthority.load(:path => path, :password => 'abc')
    end

    it "should load an EaSSL::CertificateAuthority from disk" do
      @sa.class.should == ChefSSL::Client::SigningAuthority
    end

    it "should return the CA's DN" do
      @sa.dn.should == '/C=GB/ST=London/L=London/O=Venda Ltd/OU=SSL Automation/CN=RSpec CA'
    end

    it "should sign a request" do
      csr = <<EOCSR
-----BEGIN CERTIFICATE REQUEST-----
MIH/MIGqAgEAMEUxCzAJBgNVBAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEw
HwYDVQQKDBhJbnRlcm5ldCBXaWRnaXRzIFB0eSBMdGQwXDANBgkqhkiG9w0BAQEF
AANLADBIAkEAxhmgFlQvs+htUPfVaw0BLBEiq1txCZ/C77szukpOeREtqFs3aNvF
kHZZ+XWMbcRJNwYq8Q5+bCxD4rUb0TnYrQIDAQABoAAwDQYJKoZIhvcNAQEFBQAD
QQBtQYSbjm7do2uHtDV695qIsMrJBqRDAKhREZTTQOOYvo6tO/Lcy1WywR65SM7/
zAxg/0bNxf1etMRSDsEz963S
-----END CERTIFICATE REQUEST-----
EOCSR
      data = { 'csr' => csr, 'type' => 'server', 'days' => 10 }
      host = 'localhost'
      request = ChefSSL::Client::Request.new(host, data)
      t = Time.now
      cert = @sa.sign(request)
      cert.class.should == ChefSSL::Client::IssuedCertificate
      cert.subject.should == "/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd"
      cert.not_after.to_i.should == (t + (24 * 60 * 60 * 10)).to_i
    end

  end

  describe "creating a new CA" do

    it "should create a new CA from the given DN" do
      flexmock(Dir).should_receive(:mkdir).times(4)
      flexmock(File).should_receive(:open).times(3)
        .and_yield(StringIO.new)

      name = OpenSSL::X509::Name.parse('CN=Test CA')
      ChefSSL::Client::SigningAuthority.create(name, 'test-ca', 'abcd')
    end

  end

end
