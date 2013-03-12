module RSpec
  module Chef
    module DefineLibraryGroup
      include RSpec::Chef::Matchers
      include JSONSupport
      include ChefSupport
      include Config

      def subject
        @library ||= library
      end

      def library
        ::Chef::Log.level = chef_log_level

        dna = RSpec.configuration.default_attributes

        library_name = self.class.top_level_description.downcase
        lookup_library(library_name, chef_cookbook_path, dna)
      end
    end
  end
end
