require 'spec_helper'

describe ChefSSL::Client::IssuedCertificate do

  it "should accept a CSR and a certificate" do
    req = flexmock('req')
    cert = flexmock('cert')
    c = ChefSSL::Client::IssuedCertificate.new(req, cert)
  end

  it "should accept a CSR and a certificate, and a CA" do
    req = flexmock('req')
    cert = flexmock('cert')
    ca = flexmock('ca')
    c = ChefSSL::Client::IssuedCertificate.new(req, cert, ca)
  end

  it "should provide access to the certificate details" do
    req = flexmock('req')
    path = File.expand_path('fixtures/ca/cacert.pem', File.dirname(__FILE__))
    cert = EaSSL::Certificate.load(path)

    c = ChefSSL::Client::IssuedCertificate.new(req, cert)

    c.to_pem.should_not be_nil
    c.sha1_fingerprint.should == 'E2:32:B7:4E:F4:4F:75:2A:23:AF:ED:1D:38:42:05:B1:66:CD:7F:2A'
    c.subject.should == '/C=GB/ST=London/L=London/O=Venda Ltd/OU=SSL Automation/CN=RSpec CA'
    c.issuer.should == '/C=GB/ST=London/L=London/O=Venda Ltd/OU=SSL Automation/CN=RSpec CA'
  end

  it "should save issued certificates back to the chef server" do
    flexmock(Spice) do |m|
      m.should_receive(:create_data_bag).once()
        .with(ChefSSL::Client::IssuedCertificate::DATABAG)
        .and_raise(Spice::Error::Conflict)
      m.should_receive(:create_data_bag_item).once()
    end

    req = flexmock('req') do |m|
      m.should_receive(:id).once().and_return('id')
      m.should_receive(:subject).once().and_return('subject')
      m.should_receive(:to_pem).once().and_return('req-pem-text')
      m.should_receive(:key).once().and_return('key-text')
      m.should_receive(:type).once().and_return('type')
      m.should_receive(:host).once().and_return('host')
      m.should_receive(:ca).once().and_return('ca')
    end
    cert = flexmock('cert') do |m|
      m.should_receive(:to_pem).once().and_return('cert-pem-text')
      m.should_receive(:not_before).once().and_return('not-before-date')
      m.should_receive(:not_after).once().and_return('not-after-date')
    end
    flexmock(Time).should_receive(:now).once().and_return(Time.new('2001-01-01 00:00:00'))

    c = ChefSSL::Client::IssuedCertificate.new(req, cert)
    c.save!
  end

  it "should save issued certificate + cacertificate back to the chef server" do
    flexmock(Spice) do |m|
      m.should_receive(:create_data_bag).once()
        .with(ChefSSL::Client::IssuedCertificate::DATABAG)
        .and_raise(Spice::Error::Conflict)
      m.should_receive(:create_data_bag_item).once()
    end

    req = flexmock('req') do |m|
      m.should_receive(:id).once().and_return('id')
      m.should_receive(:subject).once().and_return('subject')
      m.should_receive(:to_pem).once().and_return('req-pem-text')
      m.should_receive(:key).once().and_return('key-text')
      m.should_receive(:type).once().and_return('type')
      m.should_receive(:host).once().and_return('host')
      m.should_receive(:ca).once().and_return('ca')
    end
    cert = flexmock('cert') do |m|
      m.should_receive(:to_pem).once().and_return('cert-pem-text')
      m.should_receive(:not_before).once().and_return('not-before-date')
      m.should_receive(:not_after).once().and_return('not-after-date')
    end
    ca = flexmock('ca') do |m|
      m.should_receive('certificate.to_pem').once().and_return('cacert-pem-text')
    end
    flexmock(Time).should_receive(:now).once().and_return(Time.new('2001-01-01 00:00:00'))

    c = ChefSSL::Client::IssuedCertificate.new(req, cert, ca)
    c.save!
  end

  it "should handle a chef save error" do
    h = FlexMock.hsh(
      :name => ChefSSL::Client::IssuedCertificate::DATABAG,
      :id => 'id'
    )
    flexmock(Spice) do |m|
      m.should_receive(:create_data_bag).once()
        .with(ChefSSL::Client::IssuedCertificate::DATABAG)
        .and_raise(Spice::Error::Conflict)
      m.should_receive(:create_data_bag_item).once()
        .with(ChefSSL::Client::IssuedCertificate::DATABAG, h)
        .and_raise(Spice::Error::ClientError)
    end

    req = flexmock('req') do |m|
      m.should_receive(:id).once().and_return('id')
      m.should_receive(:subject).once().and_return('subject')
      m.should_receive(:to_pem).once().and_return('req-pem-text')
      m.should_receive(:key).once().and_return('key-text')
      m.should_receive(:type).once().and_return('type')
      m.should_receive(:host).once().and_return('host')
      m.should_receive(:ca).once().and_return('ca')
    end
    cert = flexmock('cert') do |m|
      m.should_receive(:to_pem).once().and_return('cert-pem-text')
      m.should_receive(:not_before).once().and_return('not-before-date')
      m.should_receive(:not_after).once().and_return('not-after-date')
    end
    flexmock(Time).should_receive(:now).once().and_return(Time.new('2001-01-01 00:00:00'))

    c = ChefSSL::Client::IssuedCertificate.new(req, cert)
    lambda { c.save! }.should raise_error(ChefSSL::Client::CertSaveFailed)
  end

  it "should handle a chef data bag conflict" do
    flexmock(Spice) do |m|
      m.should_receive(:create_data_bag).once()
        .with(ChefSSL::Client::IssuedCertificate::DATABAG)
        .and_raise(Spice::Error::Conflict)
      m.should_receive(:create_data_bag_item).once()
        .and_raise(Spice::Error::Conflict)
    end

    req = flexmock('req') do |m|
      m.should_receive(:id).twice().and_return('id') # called again for error msg
      m.should_receive(:subject).twice().and_return('subject') # called again for error msg
      m.should_receive(:to_pem).once().and_return('req-pem-text')
      m.should_receive(:key).once().and_return('key-text')
      m.should_receive(:type).once().and_return('type')
      m.should_receive(:host).once().and_return('host')
      m.should_receive(:ca).once().and_return('ca')
    end
    cert = flexmock('cert') do |m|
      m.should_receive(:to_pem).once().and_return('cert-pem-text')
      m.should_receive(:not_before).once().and_return('not-before-date')
      m.should_receive(:not_after).once().and_return('not-after-date')
    end
    flexmock(Time).should_receive(:now).once().and_return(Time.new('2001-01-01 00:00:00'))

    c = ChefSSL::Client::IssuedCertificate.new(req, cert)
    lambda { c.save! }.should raise_error(ChefSSL::Client::CertSaveFailed)
  end

end
