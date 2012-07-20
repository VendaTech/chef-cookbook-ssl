require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe 'zeus::solo-update', :type => :recipe do

  before(:each) do
    flexmock(Chef::EncryptedDataBagItem).should_receive(:load_secret)
    flexmock(Chef::EncryptedDataBagItem).should_receive(:load).and_return({})
  end

  describe 'update some pools' do
    let(:json_attributes) {
      {
        :fqdn => 'testhost.example.com',
        :zeus => {
          # data from dna.json
          :updates => {
            :pool1 => {
              :backends => [
                '10.0.0.1:80',
                '10.0.0.2:80'
              ]
            }
          },
          # data from ohai
          :vservers => {
            :vserver2 => {
              :pool => ['pool1'],
              :address => ['!ipgroup1'],
            }
          },
          :pools => {
            :pool1 => { }
          },
          :ipgroups => {
            :ipgroup1 => { }
          }
        }
      }
    }

    it "should update a pool" do
      should contain_zeus_pool('pool1')
        .with(:action, [:update])
        .with(:nodes, ["10.0.0.1:80", "10.0.0.2:80"])
    end
  end

  describe 'avoid updating a non-existent pool' do
    let(:json_attributes) {
      {
        :fqdn => 'testhost.example.com',
        :zeus => {
          # data from dna.json
          :updates => {
            :pool1 => {
              :backends => [
                '10.0.0.1:80',
                '10.0.0.2:80'
              ]
            }
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

    it "should not update a pool" do
      should_not contain_zeus_pool('pool1')
    end
  end
end
