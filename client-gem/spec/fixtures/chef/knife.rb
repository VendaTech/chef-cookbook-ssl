log_level                :info
log_location             STDOUT
node_name		 'rspc'
client_key		 'fixtures/chef/client.pem'
chef_server_url		 'https://chef-server.example.com'
cookbook_path           ['fixtures/chef/cookbooks']
cache_type               'BasicFile'
cache_options( :path => 'fixtures/chef/checksums' )
