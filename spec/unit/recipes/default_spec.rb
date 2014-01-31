require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe 'x509::default' do
  describe 'setup without key vault' do
    let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

    it 'installs the eassl2 gem' do
      expect(chef_run).to upgrade_chef_gem('eassl2')
    end
  end

  describe 'setup with key vault enabled' do
    before do
      ChefSpec::Server.create_data_bag('gpg_keys', {})
    end

    let(:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['x509']['key_vault'] = 'keys@example.com'
      end.converge(described_recipe)
    end

    it 'installs the eassl2 and gpgme gems, and gnupg package' do
      expect(chef_run).to upgrade_chef_gem('eassl2')
      expect(chef_run).to install_chef_gem('gpgme')
      expect(chef_run).to upgrade_package('gnupg')
    end
  end
end
