module RSpec
  module Chef
    module Matchers
      CONTAIN_PATTERN = /^contain_(.+)/

      def method_missing(method, *args, &block)
        return RSpec::Chef::Matchers::ContainResource.new(method, *args, &block) if method.to_s =~ CONTAIN_PATTERN
        super
      end

      class ContainResource
        def initialize(type, *args, &block)
          @type                  = type.to_s[CONTAIN_PATTERN, 1]
          @name                  = args.shift
          @params                = args.shift || {}
          @expected_attributes   = {}
          @unexpected_attributes = []
          @errors                = []
        end

        def matches?(recipe)
          lookup = @type
          lookup << "[#{@name.to_s}]" if @name

          resource_collection = recipe.run_context.resource_collection
          begin
            resource = resource_collection.find(lookup)
          rescue ::Chef::Exceptions::ResourceNotFound
          end
          return false unless resource

          matches = true
          @params.each do |key, value|
            unless (real_value = resource.params[key.to_sym]) == value
              @errors << "#{key} expected to be #{value} but it is #{real_value}"
              matches = false
            end
          end

          @expected_attributes.each do |key, value|
            unless (real_value = resource.send(key.to_sym)) == value
              @errors << "#{key} expected to be #{value} but it is #{real_value}"
              matches = false
            end
          end

          @unexpected_attributes.flatten.each do |attr|
            unless (real_value = resource.send(attr.to_sym)) == nil
              @errors << "#{attr} expected to be nil but it is #{real_value}"
              matches = false
            end
          end

          matches
        end

        def description
          %Q{include Resource[#{@type} @name="#{@name}"]}
        end

        def failure_message_for_should
          %Q{expected that the recipe would #{description}#{errors}}
        end

        def negative_failure_message
          %Q{expected that the recipe would not #{description}#{errors}}
        end

        def errors
          @errors.empty? ? "" : " with #{@errors.join(', and ')}"
        end

        def with(attribute, value)
          @expected_attributes[attribute] = value
          self
        end

        def without(*attributes)
          @unexpected_attributes << attributes
          self
        end
      end
    end
  end
end
