require 'spec_helper'

describe ChefSSL::Client do

  describe "load the certificate authority" do

    it "should return an EaSSL::CertificateAuthority" do
      ca = flexmock('ca')
      flexmock(ChefSSL::Client::SigningAuthority).should_receive(:load).once()
        .with(:path => '/tmp/ca', :password => 'abc')
        .and_return(ca)

      ChefSSL::Client.load_authority(:path => '/tmp/ca', :password => 'abc')
        .should == ca
    end

    it "should load an EaSSL::CertificateAuthority from disk" do
      path = File.expand_path('fixtures/ca', File.dirname(__FILE__))
      ca = ChefSSL::Client.load_authority(:path => path, :password => 'abc')
      ca.class.should == ChefSSL::Client::SigningAuthority
      ca.dn.should == '/C=GB/ST=London/L=London/O=Venda Ltd/OU=SSL Automation/CN=RSpec CA'
    end

  end

  describe "methods involving connecting to Chef" do

    before(:each) do
      chef_path = File.expand_path('fixtures/chef/knife.rb', File.dirname(__FILE__))
      flexmock(File).should_receive(:expand_path)
        .and_return(chef_path)

      setup = flexmock('s') do |m|
        m.should_receive(:server_url=).once()
        m.should_receive(:client_name=).once()
        m.should_receive(:client_key=).once()
        m.should_receive(:connection_options=).once()
      end
      flexmock(Spice) do |m|
        m.should_receive(:reset)
        m.should_receive(:read_key_file).once()
        m.should_receive(:setup).and_yield(setup).once()
      end
    end

    describe "connect to Chef" do

      it "should load a knife.rb and initialize Spice from it" do
        client = ChefSSL::Client.new
      end

    end

    describe "it should search Chef for CSRs by CA" do

      it "should find a CSR by specific CA" do
        outbox = {
          'name' => {
            'id' => 'id',
            'csr' => 'csr-text'
          }
        }
        node = flexmock('node') do |m|
          m.should_receive(:name).and_return('node-name')
          m.should_receive(:normal).and_return({ 'csr_outbox' => outbox })
        end

        flexmock(Spice).should_receive(:nodes).once()
          .with('csr_outbox_*_ca:foo')
          .and_return([node])

        req = flexmock('request')

        flexmock(ChefSSL::Client::Request).should_receive(:new).once()
          .with('node-name', outbox['name'])
          .and_return(req)

        client = ChefSSL::Client.new

        lambda { |b| client.ca_search('foo', &b) }
          .should yield_with_args(req)
      end

      it "should find CSRs for all CAs" do
        outbox = {
          'name' => {
            'id' => 'id',
            'csr' => 'csr-text'
          }
        }
        node = flexmock('node') do |m|
          m.should_receive(:name).and_return('node-name')
          m.should_receive(:normal).and_return({ 'csr_outbox' => outbox })
        end

        flexmock(Spice).should_receive(:nodes).once()
          .with('csr_outbox_*')
          .and_return([node])

        req = flexmock('request')

        flexmock(ChefSSL::Client::Request).should_receive(:new).once()
          .with('node-name', outbox['name'])
          .and_return(req)

        client = ChefSSL::Client.new

        lambda { |b| client.ca_search(nil, &b) }
          .should yield_with_args(req)
      end

    end

    describe "it should search Chef for CSRs by common name" do

      it "should find a CSR by common name" do
        outbox = {
          'cn' => {
            'id' => 'ff2082aa78aea80a27cb4fb91f0350153702c16dce790a77f0bb0bfbf6899977',
            'csr' => 'csr-text'
          },
          'other' => { # should be ignored
            'id' => 'some-other-id',
            'csr' => 'csr-text'
          }
        }
        node = flexmock('node') do |m|
          m.should_receive(:name).and_return('node-name')
          m.should_receive(:normal).and_return({ 'csr_outbox' => outbox })
        end

        flexmock(Spice).should_receive(:nodes).once()
          .with('csr_outbox_*_id:ff2082aa78aea80a27cb4fb91f0350153702c16dce790a77f0bb0bfbf6899977')
          .and_return([node])

        req = flexmock('request')

        flexmock(ChefSSL::Client::Request).should_receive(:new).once()
          .with('node-name', outbox['cn'])
          .and_return(req)

        client = ChefSSL::Client.new

        lambda { |b| client.common_name_search('cn', &b) }
          .should yield_with_args(req)
      end

    end

  end

end
