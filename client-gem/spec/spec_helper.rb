require 'simplecov'
SimpleCov.start

require 'rspec'
require 'eassl'

$LOAD_PATH << File.expand_path('../lib', File.dirname(__FILE__))
require 'chef-ssl/client'

RSpec.configure do |c|
  c.mock_with 'flexmock'
end
