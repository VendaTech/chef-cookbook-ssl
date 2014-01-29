require 'minitest/spec'

module X509TestHelpers
  include MiniTest::Chef::Assertions
  include MiniTest::Chef::Context
  include MiniTest::Chef::Resources

  def refute_file(file, *args)
    refute File.file?(file), "Expected #{file} to not exist"
  end
end
