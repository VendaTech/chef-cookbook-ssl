require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'gpgme' # for GPGME::Crypto mock
require 'eassl' # for EaSSL::Key mock

describe 'x509_certificate', :type => :provider do

  before(:each) do
    search = flexmock('search') do |m|
      m.should_receive(:search).with_any_args()
    end
    flexmock(Chef::Search::Query).should_receive(:new).and_return(search).by_default
    flexmock(Chef::DataBagItem).should_receive(:load)
      .and_raise(Net::HTTPServerException.new(1, 2)).by_default
    flexmock(GPGME::Crypto).should_receive(:new).
      and_return(flexmock(:encrypt => flexmock(:read => 'test-gpg-ciphertext')))
  end

  describe 'create client csr when cert/key do not exist' do
    let(:action) { :create }
    let(:resource) {
      {
        :ca => "testCA",
        :key => "/tmp/key",
        :type => "client",
        :name => "ssl.example.com",
        :certificate => "/tmp/cert"
      }
    }

    it "should create key and temporary certificate" do
      should contain_file("/tmp/cert")
        .with(:action, [:create])
        .with(:owner, 'root')
        .with(:group, 'root')
        .with(:mode, '0644')
      should contain_file("/tmp/key")
        .with(:action, [:create])
        .with(:owner, 'root')
        .with(:group, 'root')
        .with(:mode, '0600')

      node['csr_outbox'].should have_key('ssl.example.com')
      csr = node['csr_outbox']['ssl.example.com']
      csr.should have_key('csr')
      csr.should have_key('key')
      csr.should have_key('ca')
      csr.should have_key('date')
      csr.should have_key('type')
      csr['type'].should == 'client'
    end
  end

  describe 'create client csr with non-default key size when cert/key do not exist' do
    let(:action) { :create }
    let(:resource) {
      {
        :ca => "testCA",
        :key => "/tmp/key",
        :bits => 1024,
        :type => "client",
        :name => "ssl.example.com",
        :certificate => "/tmp/cert"
      }
    }

    it "should create key and temporary certificate" do
      # show we're initializing the EaSSL::Key with the appropriate key length
      #eknew = EaSSL::Key.method(:new)
      #flexmock(EaSSL::Key).should_receive(:new).once() # temp ca key
      #  .with(FlexMock.hsh(:city => 'London'))
      #  .and_return(eknew.call())
      #flexmock(EaSSL::Key).should_receive(:new).once() # key
      #  .with(FlexMock.hsh(:bits => 1024))
      #  .and_return(eknew.call(:bits => 1024))

      should contain_file("/tmp/cert")
        .with(:action, [:create])
        .with(:owner, 'root')
        .with(:group, 'root')
        .with(:mode, '0644')
      should contain_file("/tmp/key")
        .with(:action, [:create])
        .with(:owner, 'root')
        .with(:group, 'root')
        .with(:mode, '0600')

      node['csr_outbox'].should have_key('ssl.example.com')
      csr = node['csr_outbox']['ssl.example.com']
      csr.should have_key('csr')
      csr.should have_key('key')
      csr.should have_key('ca')
      csr.should have_key('date')
      csr.should have_key('type')
      csr['type'].should == 'client'
    end
  end

  describe 'create when cert/key do not exist' do
    let(:action) { :create }
    let(:resource) {
      {
        :ca => "testCA",
        :key => "/tmp/key",
        :name => "ssl.example.com",
        :certificate => "/tmp/cert"
      }
    }

    it "should create key and temporary certificate" do
      should contain_file("/tmp/cert")
        .with(:action, [:create])
        .with(:owner, 'root')
        .with(:group, 'root')
        .with(:mode, '0644')
      should contain_file("/tmp/key")
        .with(:action, [:create])
        .with(:owner, 'root')
        .with(:group, 'root')
        .with(:mode, '0600')

      node['csr_outbox'].should have_key('ssl.example.com')
      csr = node['csr_outbox']['ssl.example.com']
      csr.should have_key('csr')
      csr.should have_key('key')
      csr.should have_key('ca')
      csr.should have_key('date')
      csr.should have_key('type')
      csr['type'].should == 'server'
    end
  end

  describe 'do nothing when csr_outbox exists' do
    let(:action) { :create }
    let(:resource) {
      {
        :ca => "testCA",
        :key => "/tmp/key",
        :name => "ssl.example.com",
        :certificate => "/tmp/cert"
      }
    }
    let(:json_attributes) {
      {
        'csr_outbox' => {
          'ssl.example.com' => {
            'baz' => 1
          }
        }
      }
    }

    it "should not touch key and certificate" do
      should contain_file("/tmp/cert")
        .with(:action, [:nothing])
      should contain_file("/tmp/key")
        .with(:action, [:nothing])
      node['csr_outbox'].should have_key('ssl.example.com')
    end
  end

  describe 'install new cert when certbag shows up' do
    let(:action) { :create }
    let(:resource) {
      {
        :ca => "testCA",
        :key => "/tmp/key",
        :name => "ssl.example.com",
        :certificate => "/tmp/cert"
      }
    }
    let(:json_attributes) {
      {
        'csr_outbox' => {
          'ssl.example.com' => {
            'baz' => 1
          }
        }
      }
    }

    it "should update certificate" do
      # Mocking search() looking for the certificate databag item
      search_query = "id:729c42d574be013c27ee3600bd87018825792c9d15057d2b0b8833796aa09e19"
      search = flexmock('search') do |m|
        m.should_receive(:search)
          .with(:certificates, search_query, FlexMock.any)
          .and_yield( {'certificate' => 'test-cert-text'} )
      end
      flexmock(Chef::Search::Query).should_receive(:new).and_return(search)

      # mocking File.size for the specific files the provider
      # expects - here, the key exists
      size_method = File.method(:size?)
      flexmock(File).should_receive(:size?).with('/tmp/key')
        .and_return(true)
      flexmock(File).should_receive(:size?).and_return do |file|
        size_method.call file
      end

      # mocking File.read to return the key
      read_method = File.method(:read)
      flexmock(File).should_receive(:read).with('/tmp/key')
        .and_return('the-key')
      flexmock(File).should_receive(:read).and_return do |file|
        read_method.call file
      end

      # the key and cert should appear to be a matched pair
      key = flexmock('key') do |m|
        m.should_receive(:n).and_return(1)
      end
      cert = flexmock('cert') do |m|
        m.should_receive('public_key.n').and_return(1)
      end
      flexmock(OpenSSL::PKey::RSA).should_receive(:new).and_return(key)
      flexmock(OpenSSL::X509::Certificate).should_receive(:new).and_return(cert)

      should contain_file("/tmp/cert")
        .with(:action, [:create])
        .with(:content, 'test-cert-text')
      should contain_file("/tmp/key")
        .with(:action, [:nothing])
      node['csr_outbox'].should_not have_key('ssl.example.com')
    end

  end

  describe 'install new cert and cacert when certbag shows up' do
    let(:action) { :create }
    let(:resource) {
      {
        :ca => "testCA",
        :key => "/tmp/key",
        :name => "ssl.example.com",
        :certificate => "/tmp/cert",
        :cacertificate => "/tmp/cacert",
      }
    }
    let(:json_attributes) {
      {
        'csr_outbox' => {
          'ssl.example.com' => {
            'baz' => 1
          }
        }
      }
    }

    it "should update certificate and install cacert" do
      # Mocking search() looking for the certificate databag item
      search_query = "id:729c42d574be013c27ee3600bd87018825792c9d15057d2b0b8833796aa09e19"
      search = flexmock('search') do |m|
        m.should_receive(:search)
          .with(:certificates, search_query, FlexMock.any)
          .and_yield({
             'certificate' => 'test-cert-text',
             'cacert' => 'test-cacert-text'
        })
      end
      flexmock(Chef::Search::Query).should_receive(:new).and_return(search)

      # mocking File.size for the specific files the provider
      # expects - here, the key exists
      size_method = File.method(:size?)
      flexmock(File).should_receive(:size?).with('/tmp/key')
        .and_return(true)
      flexmock(File).should_receive(:size?).and_return do |file|
        size_method.call file
      end

      # mocking File.read to return the key
      read_method = File.method(:read)
      flexmock(File).should_receive(:read).with('/tmp/key')
        .and_return('the-key')
      flexmock(File).should_receive(:read).and_return do |file|
        read_method.call file
      end

      # the key and cert should appear to be a matched pair
      key = flexmock('key') do |m|
        m.should_receive(:n).and_return(1)
      end
      cert = flexmock('cert') do |m|
        m.should_receive('public_key.n').and_return(1)
      end
      flexmock(OpenSSL::PKey::RSA).should_receive(:new).and_return(key)
      flexmock(OpenSSL::X509::Certificate).should_receive(:new).and_return(cert)

      should contain_file("/tmp/cert")
        .with(:action, [:create])
        .with(:content, 'test-cert-text')
      should contain_file("/tmp/cacert")
        .with(:action, [:create])
        .with(:content, 'test-cacert-text')
      should contain_file("/tmp/key")
        .with(:action, [:nothing])

      node['csr_outbox'].should_not have_key('ssl.example.com')
    end
  end

  describe 'handle mismatched key/cert when certbag shows up' do
    let(:action) { :create }
    let(:resource) {
      {
        :ca => "testCA",
        :key => "/tmp/key",
        :name => "ssl.example.com",
        :certificate => "/tmp/cert"
      }
    }
    let(:json_attributes) {
      {
        'csr_outbox' => {
          'ssl.example.com' => {
            'baz' => 1
          }
        }
      }
    }

    it "should not touch cert or key" do
      # Mocking search() looking for the certificate databag item
      search_query = "id:729c42d574be013c27ee3600bd87018825792c9d15057d2b0b8833796aa09e19"
      search = flexmock('search') do |m|
        m.should_receive(:search)
          .with(:certificates, search_query, FlexMock.any)
          .and_yield( {'certificate' => 'test-cert-text'} )
      end
      flexmock(Chef::Search::Query).should_receive(:new).and_return(search)

      # mocking File.size for the specific files the provider
      # expects - here, the key is present
      size_method = File.method(:size?)
      flexmock(File).should_receive(:size?).with('/tmp/key')
        .and_return(true)
      flexmock(File).should_receive(:size?).and_return do |file|
        size_method.call file
      end

      # mocking File.read to return the key
      read_method = File.method(:read)
      flexmock(File).should_receive(:read).with('/tmp/key')
        .and_return('the-key')
      flexmock(File).should_receive(:read).and_return do |file|
        read_method.call file
      end

      # the key and cert should appear to be mismatched
      key = flexmock('key') do |m|
        m.should_receive(:n).and_return(1)
      end
      cert = flexmock('cert') do |m|
        m.should_receive('public_key.n').and_return(2)
      end
      flexmock(OpenSSL::PKey::RSA).should_receive(:new).and_return(key)
      flexmock(OpenSSL::X509::Certificate).should_receive(:new).and_return(cert)

      should contain_file("/tmp/cert")
        .with(:action, [:nothing])
      should contain_file("/tmp/key")
        .with(:action, [:nothing])
      node['csr_outbox'].should_not have_key('ssl.example.com')
    end

  end

  describe 'handle missing key when certbag shows up' do
    let(:action) { :create }
    let(:resource) {
      {
        :ca => "testCA",
        :key => "/tmp/key",
        :name => "ssl.example.com",
        :certificate => "/tmp/cert"
      }
    }
    let(:json_attributes) {
      {
        'csr_outbox' => {
          'ssl.example.com' => {
            'baz' => 1
          }
        }
      }
    }

    it "should not touch cert or key" do
      # Mocking search() looking for the certificate databag item
      search_query = "id:729c42d574be013c27ee3600bd87018825792c9d15057d2b0b8833796aa09e19"
      search = flexmock('search') do |m|
        m.should_receive(:search)
          .with(:certificates, search_query, FlexMock.any)
          .and_yield( {'certificate' => 'test-cert-text'} )
      end
      flexmock(Chef::Search::Query).should_receive(:new).and_return(search)

      # mocking File.size for the specific files the provider
      # expects - here, the key is missing
      size_method = File.method(:size?)
      flexmock(File).should_receive(:size?).with('/tmp/key')
        .and_return(false)
      flexmock(File).should_receive(:size?).and_return do |file|
        size_method.call file
      end

      should contain_file("/tmp/cert")
        .with(:action, [:nothing])
      should contain_file("/tmp/key")
        .with(:action, [:nothing])
      node['csr_outbox'].should_not have_key('ssl.example.com')
    end

  end

end
