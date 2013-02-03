# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + '/lib/chef-ssl/client/version'

Gem::Specification.new do |s|
  s.name = "chef-ssl-client"
  s.version = ChefSSL::Client::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc" ]
  s.summary = "A command-line client the ssl cookbook's signing requirements"
  s.description = s.summary
  s.author = "Venda"
  s.email = "auto-ssl@venda.com"
  s.homepage = "https://github.com/VendaTech/chef-cookbook-ssl"

  s.add_dependency "chef",          ">= 0.10.0"
  s.add_dependency "spice",         "= 1.0.4"   # >= 1.0.6 brings breaking changes
  s.add_dependency "eassl2",        "~> 2.0.1"
  s.add_dependency "highline",      ">= 1.6.15" # < .15 apparently buggy
  s.add_dependency "commander",     "~> 4.1.0"
  s.add_dependency "multi_json",    ">= 1.0.0"
  s.add_dependency "activesupport", ">= 3.1.0"

  s.add_development_dependency "rspec", "~> 2.10.0"
  s.add_development_dependency "flexmock", "~> 0.9.0"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "rake"

  s.bindir       = "bin"
  s.executables  = %w( chef-ssl )
  s.require_path = 'lib'

  s.files = %w( README.rdoc Rakefile bin/chef-ssl )
  s.files += Dir.glob('lib/**/*')

  s
end

