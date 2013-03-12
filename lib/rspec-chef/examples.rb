require 'rspec-chef/examples/define_recipe_group.rb'
require 'rspec-chef/examples/define_provider_group.rb'
require 'rspec-chef/examples/define_library_group.rb'

RSpec.configure do |c|
  def c.escaped_path(*parts)
    Regexp.compile(parts.join('[\\\/]'))
  end

  c.include RSpec::Chef::DefineRecipeGroup, :type => :recipe, :example_group => {
    :file_path => c.escaped_path(%w[spec recipes])
  }

  c.include RSpec::Chef::DefineProviderGroup, :type => :provider, :example_group => {
    :file_path => c.escaped_path(%w[spec providers])
  }

  c.include RSpec::Chef::DefineLibraryGroup, :type => :library, :example_group => {
    :file_path => c.escaped_path(%w[spec libraries])
  }
end
