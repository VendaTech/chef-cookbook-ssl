require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'zeus::solo-destroy', :type => :recipe do

  before(:each) do
    flexmock(Chef::EncryptedDataBagItem).should_receive(:load_secret)
    flexmock(Chef::EncryptedDataBagItem).should_receive(:load).and_return({})
  end

  describe 'not deleting a vserver that does not exist' do
    let(:json_attributes) {
      {
        :zeus => {
          # data from dna.json
          :vserver => { :name => 'vserver1', :port => 80 },
          # data from ohai
          :vservers => {
            'vserver2' => {
              'pool' => ['pool1'],
              'address' => ['!ipgroup1'],
            }
          },
          :pools => {
            'pool1' => { }
          },
          :ipgroups => {
            'ipgroup1' => { }
          }
        }
      }
    }

    it "should delete a vserver only" do
      should_not contain_zeus_vserver('vserver1').with(:action, [:delete])
      should_not contain_zeus_pool('pool1').with(:action, [:delete])
      should_not contain_zeus_ipgroup('ipgroup1').with(:action, [:delete])
    end
  end

  describe 'deleting a vserver only, sharing a pool and ipgroup' do
    let(:json_attributes) {
      {
        :zeus => {
          # data from dna.json
          :vserver => { :name => 'vserver1', :port => 80 },
          # data from ohai
          :vservers => {
            'vserver1' => {
              'pool' => ['pool1'],
              'address' => ['!ipgroup1'],
            },
            'vserver2' => {
              'pool' => ['pool1'],
              'address' => ['!ipgroup1'],
            }
          },
          :pools => {
            'pool1' => { }
          },
          :ipgroups => {
            'ipgroup1' => { }
          }
        }
      }
    }

    it "should delete a vserver only" do
      should contain_zeus_vserver('vserver1').with(:action, [:delete])
      should_not contain_zeus_pool('pool1').with(:action, [:delete])
      should_not contain_zeus_ipgroup('ipgroup1').with(:action, [:delete])
    end
  end

  describe 'deleting a vserver, pool and ipgroup' do
    let(:json_attributes) {
      {
        :zeus => {
          # data from dna.json
          :vserver => { :name => 'vserver1', :port => 80 },
          # data from ohai
          :vservers => {
            'vserver1' => {
              'pool' => ['pool1'],
              'address' => ['!ipgroup1'],
            }
          },
          :pools => {
            'pool1' => { }
          },
          :ipgroups => {
            'ipgroup1' => { }
          }
        }
      }
    }

    it "should delete a vserver, pool and ipgroup" do
      should contain_zeus_vserver('vserver1').with(:action, [:delete])
      should contain_zeus_pool('pool1').with(:action, [:delete])
      should contain_zeus_ipgroup('ipgroup1').with(:action, [:delete])
    end
  end

  describe 'not deleting a pool that does not exist' do
    let(:json_attributes) {
      {
        :zeus => {
          # data from dna.json
          :vserver => { :name => 'vserver1', :port => 80 },
          # data from ohai
          :vservers => {
            'vserver1' => {
              'pool' => ['pool1'],
              'address' => ['!ipgroup1'],
            }
          },
          :pools => {
            # no pools
          },
          :ipgroups => {
            'ipgroup1' => { }
          }
        }
      }
    }

    it "should delete a vserver, pool and ipgroup" do
      should contain_zeus_vserver('vserver1').with(:action, [:delete])
      should_not contain_zeus_pool('pool1').with(:action, [:delete])
      should contain_zeus_ipgroup('ipgroup1').with(:action, [:delete])
    end
  end

  describe 'not deleting an ipgroup that does not exist' do
    let(:json_attributes) {
      {
        :zeus => {
          # data from dna.json
          :vserver => { :name => 'vserver1', :port => 80 },
          # data from ohai
          :vservers => {
            'vserver1' => {
              'pool' => ['pool1'],
              'address' => ['!ipgroup1'],
            }
          },
          :pools => {
            'pool1' => { }
          },
          :ipgroups => {
            # no ipgroups
          }
        }
      }
    }

    it "should delete a vserver, pool and ipgroup" do
      should contain_zeus_vserver('vserver1').with(:action, [:delete])
      should contain_zeus_pool('pool1').with(:action, [:delete])
      should_not contain_zeus_ipgroup('ipgroup1').with(:action, [:delete])
    end
  end

  describe 'deleting an ssl vserver only, sharing a pool and ipgroup' do
    let(:json_attributes) {
      {
        :zeus => {
          # data from dna.json
          :vserver => { :name => 'vserver1', :port => 443, :ssl => 1 },
          # data from ohai
          :vservers => {
            'vserver1-ssl' => {
              'pool' => ['pool1'],
              'address' => ['!ipgroup1'],
            },
            'vserver1' => { # sharing with our http vserver
              'pool' => ['pool1'],
              'address' => ['!ipgroup1'],
            }
          },
          :pools => {
            'pool1' => { }
          },
          :ipgroups => {
            'ipgroup1' => { }
          },
          :sslcerts => {
            'vserver1-ssl' => { }
          }
        }
      }
    }

    it "should delete a vserver only" do
      should contain_zeus_vserver('vserver1-ssl').with(:action, [:delete])
      should contain_zeus_sslcert('vserver1-ssl').with(:action, [:delete])
      should_not contain_zeus_pool('pool1').with(:action, [:delete])
      should_not contain_zeus_ipgroup('ipgroup1').with(:action, [:delete])
    end
  end

  describe 'not deleting an sslcert that does not exist' do
    let(:json_attributes) {
      {
        :zeus => {
          # data from dna.json
          :vserver => { :name => 'vserver1', :port => 443, :ssl => 1 },
          # data from ohai
          :vservers => {
            'vserver1-ssl' => {
              'pool' => ['pool1'],
              'address' => ['!ipgroup1'],
            },
            'vserver1' => { # sharing with our http vserver
              'pool' => ['pool1'],
              'address' => ['!ipgroup1'],
            }
          },
          :pools => {
            'pool1' => { }
          },
          :ipgroups => {
            'ipgroup1' => { }
          },
          :sslcerts => {
            # no sslcerts
          }
        }
      }
    }

    it "should delete a vserver only" do
      should contain_zeus_vserver('vserver1-ssl').with(:action, [:delete])
      should_not contain_zeus_sslcert('vserver1-ssl').with(:action, [:delete])
      should_not contain_zeus_pool('pool1').with(:action, [:delete])
      should_not contain_zeus_ipgroup('ipgroup1').with(:action, [:delete])
    end
  end

  describe 'deleting an ssl vserver, its pool and ipgroup' do
    let(:json_attributes) {
      {
        :zeus => {
          # data from dna.json
          :vserver => { :name => 'vserver1', :port => 443, :ssl => 1 },
          # data from ohai
          :vservers => {
            'vserver1-ssl' => {
              'pool' => ['pool1'],
              'address' => ['!ipgroup1'],
            }
          },
          :pools => {
            'pool1' => { }
          },
          :ipgroups => {
            'ipgroup1' => { }
          },
          :sslcerts => {
            'vserver1-ssl' => { }
          }
        }
      }
    }

    it "should delete a vserver only" do
      should contain_zeus_vserver('vserver1-ssl').with(:action, [:delete])
      should contain_zeus_sslcert('vserver1-ssl').with(:action, [:delete])
      should contain_zeus_pool('pool1').with(:action, [:delete])
      should contain_zeus_ipgroup('ipgroup1').with(:action, [:delete])
    end
  end

end
