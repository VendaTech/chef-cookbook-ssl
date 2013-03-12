module RSpec
  module Chef
    module JSONSupport
      # Transform JSON data into a Hash
      # If data is the path to a file it reads the file and transform its content.
      def json(data)
        if data.is_a?(Hash)
          data
        elsif File.file?(data)
          ::Chef::JSONCompat.from_json(File.read(data)) rescue {}
        else
          ::Chef::JSONCompat.from_json(data) rescue {}
        end
      end
    end
  end
end
