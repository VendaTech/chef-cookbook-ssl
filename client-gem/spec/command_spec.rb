require 'highline/simulate'
require 'spec_helper'

describe 'bin/chef-ssl' do

  before(:each) do
    FileUtils.rm_r 'tmp' if File.directory? 'tmp'
    FileUtils.mkdir 'tmp'
  end

  after(:each) do
    FileUtils.rm_r 'tmp' if File.directory? 'tmp'
  end

  describe 'makeca' do

    it "should create a new CA in response to a makeca command" do
      c = new_command_runner 'makeca', '--dn', '/O=Foo', '--ca-path', './tmp/ca'
      HighLine::Simulate.with 'new-ca-passphrase', 'new-ca-passphrase' do
        output = capture { c.run! }
        output.should =~ /Enter new CA passphrase/
        output.should =~ /Re-enter new CA passphrase/
      end
      File.directory?('tmp/ca').should be_true
    end

    it "should require a DN" do
      c = new_command_runner 'makeca', '--ca-path', './tmp/ca'
      lambda { c.run! }.should raise_error RuntimeError
      File.directory?('tmp/ca').should be_false
    end

    it "should require a valid DN" do
      c = new_command_runner 'makeca', '--dn', 'foo', '--ca-path', './tmp/ca'
      lambda { c.run! }.should raise_error RuntimeError
      File.directory?('tmp/ca').should be_false
    end

  end

  describe 'issue' do

    it "should issue an ad hoc server certificate with a 'full' DN" do
      c = new_command_runner 'issue', '--dn', '/C=GB/ST=London/L=London/O=Foo/OU=Test/CN=www.example.com/emailAddress=test@example.com', '--ca-path', './spec/fixtures/ca', '--type', 'server'
      HighLine::Simulate.with 'abc' do
        output = capture { c.run! }
        output.should =~ /Enter CA passphrase/
        output.should =~ /BEGIN RSA PRIVATE KEY/
        output.should =~ /BEGIN CERTIFICATE/
      end
    end

    it "should issue an ad hoc server certificate with a 'short' DN" do
      c = new_command_runner 'issue', '--dn', '/O=Foo', '--ca-path', './spec/fixtures/ca', '--type', 'server'
      HighLine::Simulate.with 'abc' do
        output = capture { c.run! }
        output.should =~ /Enter CA passphrase/
        output.should =~ /BEGIN RSA PRIVATE KEY/
        output.should =~ /BEGIN CERTIFICATE/
      end
    end

    it "should issue an ad hoc client certificate with a 'short' DN" do
      c = new_command_runner 'issue', '--dn', '/O=Foo', '--ca-path', './spec/fixtures/ca', '--type', 'client'
      HighLine::Simulate.with 'abc' do
        output = capture { c.run! }
        output.should =~ /Enter CA passphrase/
        output.should =~ /BEGIN RSA PRIVATE KEY/
        output.should =~ /BEGIN CERTIFICATE/
      end
    end

  end

end
