module RSpec
  module Chef
    module DefineRecipeGroup
      include RSpec::Chef::Matchers
      include JSONSupport
      include ChefSupport
      include Config

      def subject
        @recipe ||= recipe
      end

      def recipe
        ::Chef::Log.level = chef_log_level
        cookbook_name = self.class.top_level_description.downcase
        lookup_recipe(cookbook_name, chef_cookbook_path, node_dna)
      end
    end
  end
end
