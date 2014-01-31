require File.expand_path('../../spec_helper', File.dirname(__FILE__))

cacert =<<EOCERT
-----BEGIN CERTIFICATE-----
MIICPDCCAaUCEHC65B0Q2Sk0tjjKewPMur8wDQYJKoZIhvcNAQECBQAwXzELMAkG
A1UEBhMCVVMxFzAVBgNVBAoTDlZlcmlTaWduLCBJbmMuMTcwNQYDVQQLEy5DbGFz
cyAzIFB1YmxpYyBQcmltYXJ5IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTk2
MDEyOTAwMDAwMFoXDTI4MDgwMTIzNTk1OVowXzELMAkGA1UEBhMCVVMxFzAVBgNV
BAoTDlZlcmlTaWduLCBJbmMuMTcwNQYDVQQLEy5DbGFzcyAzIFB1YmxpYyBQcmlt
YXJ5IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MIGfMA0GCSqGSIb3DQEBAQUAA4GN
ADCBiQKBgQDJXFme8huKARS0EN8EQNvjV69qRUCPhAwL0TPZ2RHP7gJYHyX3KqhE
BarsAx94f56TuZoAqiN91qyFomNFx3InzPRMxnVx0jnvT0Lwdd8KkMaOIG+YD/is
I19wKTakyYbnsZogy1Olhec9vn2a/iRFM9x2Fe0PonFkTGUugWhFpwIDAQABMA0G
CSqGSIb3DQEBAgUAA4GBALtMEivPLCYATxQT3ab7/AoRhIzzKBxnki98tsX63/Do
lbwdj2wsqFHMc9ikwFPwTtYmwHYBV4GSXiHx0bH/59AhWM1pF+NEHJwZRDmJXNyc
AA9WjQKZ7aKQRUzkuxCkPfAyAw7xzvjoyVGM5mKf5p/AfbdynMk2OmufTqj/ZA1k
-----END CERTIFICATE-----
EOCERT

describe 'x509::localca' do
  describe 'creating a new CA' do
    before do
      ChefSpec::Server.create_data_bag('certificates', {
          'test' => { 'cacert' => cacert }
        })
    end

    let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

    it 'creates the CA file' do
      expect(chef_run).to create_file('/etc/pki/tls/certs/415660c1.0')
    end
  end

  describe 'not recreating an existing CA' do
    before do
      ChefSpec::Server.create_data_bag('certificates', {
          'test' => { 'cacert' => cacert }
        })
    end

    let(:chef_run) do
      ChefSpec::Runner.new do |node|
        node.set['cacerts']['/etc/pki/tls/certs/415660c1.0'] = cacert
      end.converge(described_recipe)
    end

    it 'creates the CA file' do
      expect(chef_run).to_not create_file('/etc/pki/tls/certs/415660c1.0')
    end
  end
end
