require 'spec_helper'
require 'gpgme'

describe "gpg::gpg", :type => 'library' do

  before(:all) do
    search = flexmock('search') do |m|
      m.should_receive(:search).with_any_args()
    end
    flexmock(Chef::Search::Query).should_receive(:new).and_return(search)
  end

  it { should respond_to :gpg_encrypt }

  it "should notice when there are no recipients specified" do
    lambda { gpg_encrypt("foo", nil) }.should raise_error(RuntimeError)
  end

  it "should encrypt plaintext to the recipients" do
    data = flexmock('data') do |m|
      m.should_receive(:read).once()
      .and_return('ciphertext')
    end
    gpgme = flexmock('gpgme') do |m|
      m.should_receive(:encrypt).once()
        .with("foo", :recipients => "foo@example.com")
        .and_return(data)
    end
    flexmock(GPGME::Crypto).should_receive(:new).and_return(gpgme)
    gpg_encrypt("foo", "foo@example.com").should == 'ciphertext'
  end

end
