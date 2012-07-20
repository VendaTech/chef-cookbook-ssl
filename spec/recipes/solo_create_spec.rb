require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'zeus::solo-create', :type => :recipe do

  before(:each) do
    flexmock(Chef::EncryptedDataBagItem).should_receive(:load_secret)
    flexmock(Chef::EncryptedDataBagItem).should_receive(:load).and_return({})
  end

  describe 'create a new vserver, pool and ipgroup when nothing already exists' do
    let(:json_attributes) {
      {
        :fqdn => 'testhost.example.com',
        :zeus => {
          # data from dna.json
          :vserver => {
            :name => 'vserver1',
            :port => 80,
            :hostname => 'vserver1.example.com',
            :ip => '172.16.1.1',
            :backends => [
              { :ip => '10.0.0.1', :port => 80 },
              { :ip => '10.0.0.2', :port => 80 },
            ]
          },
          # data from ohai
          :vservers => {
            # no vservers
          },
          :pools => {
            # no pools
          },
          :ipgroups => {
            # no ipgroups
          }
        }
      }
    }

    it "should create vserver, pool and ipgroup" do
      should contain_zeus_vserver('vserver1')
        .with(:action, [:create])
        .with(:protocol, 'http')
        .with(:port, 80)
        .with(:default_pool, 'vserver1')
        .with(:ipgroup, 'vserver1')

      should contain_zeus_pool('vserver1')
        .with(:action, [:create])
        .with(:nodes, ["10.0.0.1:80", "10.0.0.2:80"])

      should contain_zeus_ipgroup('vserver1')
        .with(:action, [:create])
        .with(:ipaddress, '172.16.1.1')
        .with(:ztm, 'testhost.example.com')

    end
  end

  describe 'create a new vserver and pool, sharing an existing ipgroup' do
    let(:json_attributes) {
      {
        :fqdn => 'testhost.example.com',
        :zeus => {
          # data from dna.json
          :vserver => {
            :name => 'vserver1',
            :port => 8080,
            :hostname => 'vserver1.example.com',
            :ip => '172.16.1.1',
            :backends => [
              { :ip => '10.0.0.3', :port => 80 },
              { :ip => '10.0.0.4', :port => 80 },
            ]
          },
          # data from ohai
          :vservers => {
            :vserver1 => {
              :pool => ['vserver1'],
              :address => ['!vserver1'],
              :port => [80]
            }
          },
          :pools => {
            :vserver1 => {
              :nodes => [
                "10.0.0.1:80",
                "10.0.0.2:80"
              ]
            }
          },
          :ipgroups => {
            :vserver1 => {
              :ipaddresses => ['172.16.1.1'],
            }
          }
        }
      }
    }

    it "should create vserver and pool" do
      should contain_zeus_vserver('vserver1-8080')
        .with(:action, [:create])
        .with(:protocol, 'http')
        .with(:port, 8080)
        .with(:default_pool, 'vserver1-8080')
        .with(:ipgroup, 'vserver1')

      should contain_zeus_pool('vserver1-8080')
        .with(:action, [:create])
        .with(:nodes, ["10.0.0.3:80", "10.0.0.4:80"])

      should_not contain_zeus_ipgroup('vserver1')
    end
  end

  describe 'create a new vserver where its pool name is taken' do
    let(:json_attributes) {
      {
        :fqdn => 'testhost.example.com',
        :zeus => {
          # data from dna.json
          :vserver => {
            :name => 'vserver1',
            :port => 8080,
            :hostname => 'vserver1.example.com',
            :ip => '172.16.1.1',
            :backends => [
              { :ip => '10.0.0.3', :port => 80 },
              { :ip => '10.0.0.4', :port => 80 },
            ]
          },
          # data from ohai
          :vservers => {
            :vserver1 => {
              :pool => ['vserver1'],
              :address => ['!vserver1'],
              :port => [80]
            },
            'vserver1-ssl'.to_sym => {
              :pool => ['vserver1'],
              :address => ['!vserver1'],
              :port => [443]
            }
          },
          :pools => {
            :vserver1 => {
              :nodes => [
                "10.0.0.1:80",
                "10.0.0.2:80"
              ]
            },
            'vserver1-8080'.to_sym => {
              :nodes => [
                "10.0.0.5:80",
                "10.0.0.6:80"
              ]
            }
          },
          :ipgroups => {
            :vserver1 => {
              :ipaddresses => ['172.16.1.1'],
            }
          }
        }
      }
    }

    it "should create vserver and pool" do
      lambda { subject }.should raise_error(RuntimeError)
    end

  end

  describe 'create a new vserver, sharing an existing pool and ipgroup' do
    let(:json_attributes) {
      {
        :fqdn => 'testhost.example.com',
        :zeus => {
          # data from dna.json
          :vserver => {
            :name => 'vserver1',
            :port => 8080,
            :hostname => 'vserver1.example.com',
            :ip => '172.16.1.1',
            :backends => [
              { :ip => '10.0.0.1', :port => 80 },
              { :ip => '10.0.0.2', :port => 80 },
            ]
          },
          # data from ohai
          :vservers => {
            :vserver1 => {
              :pool => ['vserver1'],
              :address => ['!vserver1'],
              :port => [80]
            }
          },
          :pools => {
            :vserver1 => {
              :nodes => [
                "10.0.0.1:80",
                "10.0.0.2:80"
              ]
            }
          },
          :ipgroups => {
            :vserver1 => {
              :ipaddresses => ['172.16.1.1'],
            }
          }
        }
      }
    }


    it "should create vserver only" do
      should contain_zeus_vserver('vserver1-8080')
        .with(:action, [:create])
        .with(:protocol, 'http')
        .with(:port, 8080)
        .with(:default_pool, 'vserver1')
        .with(:ipgroup, 'vserver1')

      should_not contain_zeus_pool('vserver1')
      should_not contain_zeus_ipgroup('vserver1')
    end
  end

  describe 'create a new ssl vserver, sharing the corresponding non-ssl pool and ipgroup' do
    let(:json_attributes) {
      {
        :fqdn => 'testhost.example.com',
        :zeus => {
          # data from dna.json
          :vserver => {
            :name => 'vserver1',
            :port => 443,
            :ssl => true,
            :hostname => 'vserver1.example.com',
            :ip => '172.16.1.1',
            :backends => [
              { :ip => '10.0.0.1', :port => 80 },
              { :ip => '10.0.0.2', :port => 80 },
            ]
          },
          # data from ohai
          :vservers => {
            :vserver1 => {
              :pool => ['vserver1'],
              :address => ['!vserver1'],
              :port => [80]
            }
          },
          :pools => {
            :vserver1 => {
              :nodes => [
                "10.0.0.1:80",
                "10.0.0.2:80"
              ]
            }
          },
          :ipgroups => {
            :vserver1 => {
              :ipaddresses => ['172.16.1.1'],
            }
          }
        }
      }
    }


    it "should create vserver only" do
      should contain_zeus_vserver('vserver1-ssl')
        .with(:action, [:create])
        .with(:protocol, 'https')
        .with(:port, 443)
        .with(:default_pool, 'vserver1')
        .with(:ipgroup, 'vserver1')

      should_not contain_zeus_pool('vserver1')
      should_not contain_zeus_ipgroup('vserver1')
    end
  end

  describe 'create a new ssl vserver, pool and ipgroup when nothing already exists' do
    let(:json_attributes) {
      {
        :fqdn => 'testhost.example.com',
        :zeus => {
          # data from dna.json
          :vserver => {
            :name => 'vserver1',
            :port => 443,
            :ssl => true,
            :hostname => 'vserver1.example.com',
            :ip => '172.16.1.1',
            :backends => [
              { :ip => '10.0.0.1', :port => 80 },
              { :ip => '10.0.0.2', :port => 80 },
            ]
          },
          # data from ohai
          :vservers => {
            # no vservers
          },
          :pools => {
            # no pools
          },
          :ipgroups => {
            # no ipgroups
          },
          :sslcerts => {
            # no sslcerts
          }
        }
      }
    }

    it "should create sslcert, vserver, pool and ipgroup" do
      # mocking File.exists? for the specific files the recipe checks for
      exists_method = File.method(:exists?)
      flexmock(File).should_receive(:exists?).with('/etc/ssl/vserver1.example.com.key')
        .and_return(true)
      flexmock(File).should_receive(:exists?).with('/etc/ssl/vserver1.example.com.cert')
        .and_return(true)
      flexmock(File).should_receive(:exists?).and_return do |file|
        exists_method.call file
      end

      should contain_zeus_sslcert('vserver1-ssl')
        .with(:action, [:create])
        .with(:certificate, '/etc/ssl/vserver1.example.com.cert')
        .with(:key, '/etc/ssl/vserver1.example.com.key')

      should contain_zeus_vserver('vserver1-ssl')
        .with(:action, [:create])
        .with(:protocol, 'https')
        .with(:port, 443)
        .with(:default_pool, 'vserver1')
        .with(:ipgroup, 'vserver1')

      should contain_zeus_pool('vserver1')
        .with(:action, [:create])
        .with(:nodes, ["10.0.0.1:80", "10.0.0.2:80"])

      should contain_zeus_ipgroup('vserver1')
        .with(:action, [:create])
        .with(:ipaddress, '172.16.1.1')
        .with(:ztm, 'testhost.example.com')

    end
  end

end
