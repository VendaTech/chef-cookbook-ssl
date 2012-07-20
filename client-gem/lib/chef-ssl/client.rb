require 'spice'
require 'eassl'
require 'json'
require 'openssl'
require 'digest/sha2'
require 'active_support/hash_with_indifferent_access'
require 'chef/config'
require 'chef/node'

require 'chef-ssl/client/version'
require 'chef-ssl/client/request'
require 'chef-ssl/client/signing_authority'
require 'chef-ssl/client/issued_certificate'

module ChefSSL
  class Client

    def initialize
      path = File.expand_path('knife.rb', '~/.chef')
      Chef::Config.from_file(path)
      Spice.reset
      Spice.setup do |s|
        s.server_url = Chef::Config.chef_server_url
        s.client_name = Chef::Config.node_name
        s.client_key = Spice.read_key_file(File.expand_path(Chef::Config.client_key))
      end
    end

    def self.load_authority(options)
      SigningAuthority.load(
        :path => options[:path],
        :password => options[:password]
      )
    end

    def ca_search(ca=nil)
      if ca
        nodes = Spice.nodes("csr_outbox_*_ca:#{ca}")
      else
        nodes = Spice.nodes("csr_outbox_*")
      end
      nodes.each do |node|
        node.normal['csr_outbox'].each do |id, data|
          next if data['csr'].nil? # XXX warn, raise?
          yield Request.new(node.name, data)
        end
      end
    end

    def common_name_search(name)
      name_sha = Digest::SHA256.new << name
      cert_id = name_sha.to_s
      nodes = Spice.nodes("csr_outbox_*_id:#{cert_id}")
      nodes.each do |node|
        node.normal['csr_outbox'].each do |id, data|
          next unless data['id'] == cert_id
          next if data['csr'].nil? # XXX warn, raise?
          yield Request.new(node.name, data)
        end
      end
    end

  end
end
