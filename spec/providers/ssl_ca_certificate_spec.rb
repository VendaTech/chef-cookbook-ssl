require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'ssl_ca_certificate', :type => :provider do

  describe 'install only the cacert' do
    let(:action) { :create }
    let(:resource) {
      {
        :ca => "testCA",
        :cacertificate => "/tmp/cacert"
      }
    }
    let(:json_attributes) do
      { }
    end

    it "should install cacert" do
      search = flexmock('search') do |m|
        m.should_receive(:search).once()
        m.should_receive(:search).once()
          .with('certificates', 'ca:testCA', Proc)
          .and_yield({ 'ca' => 'testCA', 'cacert' => 'test-cacert-text' })
      end
      flexmock(Chef::Search::Query).should_receive(:new).and_return(search)
      
      should contain_file("/tmp/cacert")
       .with(:content, 'test-cacert-text')
       .with(:action, [:create])
    end

  end

  describe 'install only the cacert when it is updated' do
    let(:action) { :create }
    let(:resource) {
      {
        :ca => "testCA",
        :cacertificate => "/tmp/cacert"
      }
    }
    let(:json_attributes) do
      {
        'cacerts' => {
          'testCA' => 'old-cacert-text'
        }
      }
    end

    it "should install cacert" do
      search = flexmock('search') do |m|
        m.should_receive(:search).once()
        m.should_receive(:search).once()
          .with('certificates', 'ca:testCA', Proc)
          .and_yield({ 'ca' => 'testCA', 'cacert' => 'test-cacert-text' })
      end
      flexmock(Chef::Search::Query).should_receive(:new).and_return(search)

      should contain_file("/tmp/cacert")
       .with(:content, 'test-cacert-text')
       .with(:action, [:create])
    end

  end

  describe 'do not always update a cacert' do
    let(:action) { :create }
    let(:resource) {
      {
        :ca => "testCA",
        :cacertificate => "/tmp/cacert"
      }
    }
    let(:json_attributes) do
      {
        'cacerts' => {
          'testCA' => 'test-cacert-text'
        }
      }
    end

    it "should not install cacert" do
      search = flexmock('search') do |m|
        m.should_receive(:search).once()
        m.should_receive(:search).once()
          .with('certificates', 'ca:testCA', Proc)
          .and_yield({ 'ca' => 'testCA', 'cacert' => 'test-cacert-text' })
      end
      flexmock(Chef::Search::Query).should_receive(:new).and_return(search)

      should_not contain_file("/tmp/cacert")
    end

  end
end
