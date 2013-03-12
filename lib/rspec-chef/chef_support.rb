module RSpec
  module Chef
    module ChefSupport

      class Library; end

      $cookbooks = Hash.new

      include ::Chef::Mixin::ConvertToClassName

      def lookup_recipe(cookbook_name, cookbook_path, dna)
        run_context = load_cookbook(cookbook_name, cookbook_path, dna)

        recipe_name = ::Chef::Recipe.parse_recipe_name(cookbook_name)
        cookbook = run_context.cookbook_collection[recipe_name[0]]
        cookbook.load_recipe(recipe_name[1], run_context)
      end

      def lookup_provider(provider_full_name, cookbook_path, dna, resource)
        cookbook_name = provider_full_name.gsub(/_.+$/, '')
        provider_name = provider_full_name.gsub(/^.+?_/, '')

        if cookbook_name.nil? || provider_name.nil?
          raise "couldn't parse '#{provider_full_name}' for a cookbook/provider name"
        end

        run_context = load_cookbook(cookbook_name, cookbook_path, dna)

        provider_class = ::Chef::Provider.const_get(convert_to_class_name(provider_full_name))
        resource_class = ::Chef::Resource.const_get(convert_to_class_name(provider_full_name))

        new_resource = resource_class.new(resource['name'], run_context)
        resource.each do |k, v|
          new_resource.instance_variable_set("@#{k}".to_sym, v)
        end

        provider_class.new(new_resource, run_context)
      end

      def lookup_library(library_full_name, cookbook_path, dna)
        match = library_full_name.match(/^([^_]+)::(.+)$/)
        cookbook_name = match[1]
        library_name = match[2]

        run_context = load_cookbook(cookbook_name, cookbook_path, dna)

        cookbook = run_context.cookbook_collection[cookbook_name]
        library_class = Class.new Library do |cls|
          cookbook.segment_filenames(:libraries).each do |filename|
            if filename.match(/#{library_name}.rb$/)
              ::Chef::Log.debug("Loading cookbook #{cookbook_name}'s library file: #{filename}")
              cls.class_eval(File.read(filename))
            end
          end
        end

        library_class.new
      end

      private

      def load_cookbook(cookbook_name, cookbook_path, dna)
        cookbook_collection = ::Chef::CookbookCollection.new(::Chef::CookbookLoader.new(*cookbook_path))
        node = ::Chef::Node.new
        node.consume_attributes(dna)

        devnull = File.open('/dev/null', 'w+')
        formatter = ::Chef::Formatters.new("null", devnull, devnull)
        events = ::Chef::EventDispatch::Dispatcher.new(formatter)
        run_context = ::Chef::RunContext.new(node, cookbook_collection, events)

        run_list = ::Chef::RunList.new(cookbook_name)
        silently do
          if !$cookbooks.has_key?(cookbook_name)
            run_context.load(run_list.expand('_default', 'disk'))
            $cookbooks[cookbook_name] = true
          end
        end
        run_context.send(:load_attributes)

        run_context
      end

      def silently
        begin
          verbose = $VERBOSE
          $VERBOSE = nil
          yield
        ensure
          $VERBOSE = verbose
        end
      end
    end
  end
end
