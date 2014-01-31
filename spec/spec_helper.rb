require 'chefspec'
require 'chefspec/librarian'
require 'chefspec/server'
require 'flexmock'

RSpec.configure do |c|
  c.mock_with 'flexmock'
end
