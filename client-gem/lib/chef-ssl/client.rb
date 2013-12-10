require 'spice'
require 'eassl'
require 'json'
require 'openssl'
require 'digest/sha2'
require 'active_support/hash_with_indifferent_access'
require 'chef/knife'
require 'chef/config'
require 'chef/node'

require 'chef-ssl/client/version'
require 'chef-ssl/client/request'
require 'chef-ssl/client/signing_authority'
require 'chef-ssl/client/issued_certificate'

module ChefSSL
  class Client

    def initialize
      Chef::Knife.new.tap do |knife|
        # Set the log-level, knife style. This equals :error level
        Chef::Config[:verbosity] = knife.config[:verbosity] ||= 0
        knife.configure_chef
      end

      Spice.reset

      # avoid Spice issue if chef_server_url has a trailing slash.
      chef_server_url = Chef::Config.chef_server_url
      chef_server_url.gsub!(/\/$/, '')

      if Chef::Config.ssl_verify_mode == :verify_none
        verify_mode = OpenSSL::SSL::VERIFY_NONE
      else
        verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      Spice.setup do |s|
        s.server_url = chef_server_url
        s.client_name = Chef::Config.node_name
        s.client_key = Spice.read_key_file(File.expand_path(Chef::Config.client_key))
        s.connection_options = {
          :ssl => {
            :verify_mode => verify_mode,
            :client_cert => Chef::Config.ssl_client_cert,
            :client_key => Chef::Config.ssl_client_key,
            :ca_path => Chef::Config.ssl_ca_path,
            :ca_file => Chef::Config.ssl_ca_file,
          }
        }
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
        next if node.normal['csr_outbox'].nil?
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
