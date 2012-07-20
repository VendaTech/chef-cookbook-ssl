require 'spec_helper'

describe ChefSSL::Client::Request do

  it "should accept a host and data" do
    host = 'hostname'
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
    data = { 'csr' => csr }
    request = ChefSSL::Client::Request.new(host, data)
    request.days.should == (365 * 5)
  end

  it "should accept a host, data and csr" do
    host = 'hostname'
    data = {
      'type' => 'server',
      'ca' => 'MyCA',
      'id' => '0000',
      'name' => 'www.example.com',
      'key' => 'encrypted-key-material',
      'days' => 365
    }
    csr = flexmock('csr')

    request = ChefSSL::Client::Request.new(host, data, csr)
    request.host.should == 'hostname'
    request.csr.should == csr
    request.type.should == 'server'
    request.ca.should == 'MyCA'
    request.id.should == '0000'
    request.name.should == 'www.example.com'
    request.key.should == 'encrypted-key-material'
    request.days.should == 365
  end

  it "should provide access to csr details" do
    host = 'hostname'
    data = {}
    csr = flexmock('csr') do |m|
      m.should_receive(:subject).and_return('subject')
      m.should_receive(:to_pem).and_return('csr-pem-text')
    end
    request = ChefSSL::Client::Request.new(host, data, csr)
    request.subject.should == 'subject'
    request.to_pem.should == 'csr-pem-text'
  end

  it "should accept certificate text to issue against the request" do
    host = 'hostname'
    data = {}
    csr = flexmock('csr')
    request = ChefSSL::Client::Request.new(host, data, csr)

    cert = <<EOCERT
-----BEGIN CERTIFICATE-----
MIIB0zCCAX2gAwIBAgIJAI1zth0ifh2VMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMTIwNzA2MTExNTA3WhcNMTUwNzA2MTExNTA3WjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAMYZ
oBZUL7PobVD31WsNASwRIqtbcQmfwu+7M7pKTnkRLahbN2jbxZB2Wfl1jG3ESTcG
KvEOfmwsQ+K1G9E52K0CAwEAAaNQME4wHQYDVR0OBBYEFL1tvycT0mAPZxKXyolF
yKwXcB3BMB8GA1UdIwQYMBaAFL1tvycT0mAPZxKXyolFyKwXcB3BMAwGA1UdEwQF
MAMBAf8wDQYJKoZIhvcNAQEFBQADQQBjhH5joyBYYe9Kjz/7jrPQvlTNPy9kH45I
PRs+B/Tc85hPFHaPwEpePzWnZS3I5AtPjtpVyMel+kZ4B7Vfrzxr
-----END CERTIFICATE-----
EOCERT

    issued_cert = request.issue_certificate(cert)
    issued_cert.class.should == ChefSSL::Client::IssuedCertificate
  end

  it "should create a new request" do
    key = flexmock('key')
    name = {
      :common_name => 'cn'
    }
    req = ChefSSL::Client::Request.create(key, 'server', name)
    req.class.should == ChefSSL::Client::Request
  end

end
