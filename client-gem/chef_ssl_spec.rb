require 'spec_helper'

describe 'chef-ssl' do

  # before(:each) do
  #   @input = StringIO.new
  #   @output = StringIO.new
  #   $terminal = HighLine.new @input, @output
  #   @terminal = $terminal
  # end

  # after(:each) do
  #   $terminal = @terminal
  # end

  describe 'global options' do

    it "should run help" do
      args = ['--help']
      run_command(args)
      output.should match('Chef-automated SSL certificate signing tool')
    end

    it "should run version" do
      args = ['--version']
      run_command(args)
      output.should match(ChefSSL::Client::VERSION)
    end

  end

  # describe 'issue' do

  #   it "should run help" do
  #     args = '--help'
  #     Commander::Runner.new(args).run!
  #   end

  # end

  # describe 'makeca' do

  #   it "should run help" do
  #     args = '--help'
  #     Commander::Runner.new(args).run!
  #   end

  # end

  # describe 'search' do

  #   it "should run help" do
  #     args = '--help'
  #     Commander::Runner.new(args).run!
  #   end

  # end

  # describe 'sign' do

  #   it "should run help" do
  #     args = '--help'
  #     Commander::Runner.new(args).run!
  #   end

  # end

  # describe 'autosign' do

  #   it "should run help" do
  #     args = '--help'
  #     Commander::Runner.new(args).run!
  #   end

  # end

end
