module RSpec
  module Chef
    module DefineProviderGroup
      include RSpec::Chef::Matchers
      include JSONSupport
      include ChefSupport
      include Config

      def subject
        @provider ||= provider
      end

      def node
        subject.node
      end

      def provider
        raise "must define :resource" unless self.respond_to?(:resource)
        raise "must define :action" unless self.respond_to?(:action)

        ::Chef::Log.level = chef_log_level

        provider_name = self.class.top_level_description.downcase
        provider = lookup_provider(provider_name, chef_cookbook_path, node_dna, resource)

        method = "action_#{action}"
        provider.send(method)

        provider
      end
    end
  end
end
