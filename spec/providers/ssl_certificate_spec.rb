require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'gpgme' # for GPGME::Crypto mock
require 'eassl' # for EaSSL::Key mock

describe 'ssl_certificate', :type => :provider do

  before(:each) do
    search = flexmock('search') do |m|
      m.should_receive(:search).with_any_args()
    end
    flexmock(Chef::Search::Query).should_receive(:new).and_return(search)
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
      eknew = EaSSL::Key.method(:new)
      flexmock(EaSSL::Key).should_receive(:new).once() # key
        .with(FlexMock.hsh(:bits => 1024))
        .and_return(eknew.call(:bits => 1024))
      flexmock(EaSSL::Key).should_receive(:new).once() # temp ca key
        .and_return(eknew.call())

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
    let(:json_attributes) do
      {
        'csr_outbox' => {
          'ssl.example.com' => {
            'baz' => 1
          }
        }
      }
    end

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
    let(:json_attributes) do
      {
        'csr_outbox' => {
          'ssl.example.com' => {
            'baz' => 1
          }
        }
      }
    end

    it "should update certificate" do
      flexmock(Chef::DataBagItem).should_receive(:load)
        .and_return({
          'certificate' => 'test-cert-text'
        })

      # mocking File.size for the specific files the provider
      size_method = File.method(:size?)
      flexmock(File).should_receive(:size?).with('/tmp/key')
        .and_return(true)
      flexmock(File).should_receive(:size?).and_return do |file|
        size_method.call file
      end

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
    let(:json_attributes) do
      {
        'csr_outbox' => {
          'ssl.example.com' => {
            'baz' => 1
          }
        }
      }
    end

    it "should update certificate and install cacert" do
      flexmock(Chef::DataBagItem).should_receive(:load)
        .and_return({
          'certificate' => 'test-cert-text',
          'cacert' => 'test-cacert-text'
        })

      # mocking File.size for the specific files the provider
      size_method = File.method(:size?)
      flexmock(File).should_receive(:size?).with('/tmp/key')
        .and_return(true)
      flexmock(File).should_receive(:size?).and_return do |file|
        size_method.call file
      end

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
    let(:json_attributes) do
      {
        'csr_outbox' => {
          'ssl.example.com' => {
            'baz' => 1
          }
        }
      }
    end

    it "should not touch cert or key" do
      flexmock(Chef::DataBagItem).should_receive(:load)
        .and_return({
          'certificate' => 'test-cert-text'
        })

      # mocking File.size for the specific files the provider
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
