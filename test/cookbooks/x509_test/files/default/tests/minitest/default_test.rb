require_relative "./support/helpers"

describe_recipe "x509_test::default" do
  include X509TestHelpers

  describe "new.example.com" do
    it "should create the cert, cacert and key files" do
      assert_file "/tmp/new.example.com.cert", "root", "root", "0644"
      assert_file "/tmp/new.example.com.cacert", "root", "root", "0644"
      assert_file "/tmp/new.example.com.key", "root", "root", "0600"
    end
    it "should have put a CSR in the outbox" do
      assert node['csr_outbox']['new.example.com']
    end
  end

  describe "created.example.com" do
    it "should create the cert, cacert and key files" do
      assert_file "/tmp/created.example.com.cert", "root", "root", "0644"
      assert_file "/tmp/created.example.com.cacert", "root", "root", "0644"
      assert_file "/tmp/created.example.com.key", "root", "root", "0600"
    end
    it "should have cleared the outbox" do
      refute node['csr_outbox']['created.example.com']
    end
  end

  describe "nokey.example.com" do
    it "should NOT create the cert, cacert and key files" do
      refute_file "/tmp/nokey.example.com.cert", "root", "root", "0644"
      refute_file "/tmp/nokey.example.com.cacert", "root", "root", "0644"
      refute_file "/tmp/nokey.example.com.key", "root", "root", "0600"
    end
    it "should have not have put anything in the outbox" do
      refute node['csr_outbox']['created.example.com']
    end
  end

end
