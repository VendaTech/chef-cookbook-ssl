module RSpec
  module Chef
    module Config

      def chef_cookbook_path
        path = self.respond_to?(:cookbook_path) ? cookbook_path : RSpec.configuration.cookbook_path
        if path.class == Array
          path.reverse!
        end

        path
      end

      def node_dna
        ::Chef::Mixin::DeepMerge.merge(
          RSpec.configuration.default_attributes,
          json(self.respond_to?(:json_attributes) ? json_attributes : RSpec.configuration.json_attributes)
        )
      end

      def chef_log_level
        self.respond_to?(:log_level) ? log_level : RSpec.configuration.log_level
      end

    end
  end
end

