log_level      :info
log_location   STDOUT
node_name      'testhost'
cache_type     'BasicFile'
cache_options( :path => "#{ENV['HOME']}/.chef/checksums" )
