require 'rspec'
require 'rspec-chef'

class Chef::Resource
  def run_action(action)
  end
end

RSpec.configure do |c|
  c.cookbook_path = File.expand_path('../../..', __FILE__)
  c.mock_with :flexmock
  c.log_level = :fatal
  c.default_attributes = {
    'platform' => 'centos',
    'platform_version' => '5.8',
    'kernel' => {
      'machine' => 'i386'
    },
    'languages' => {
      'ruby' => {
        'bin_dir' => '/usr/bin'
      }
    },
    'chef_packages' => {
      'chef' => {
        'version' => Chef::VERSION
      }
    },
    'fqdn' => 'host.example.com',
    'domain' => 'example.com',
    'memory' => {
      'total' => 1024
    }
  }
end
