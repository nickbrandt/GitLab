# frozen_string_literal: true
module Gitlab
  module Config
    module Entry
      class Builder
        attr_reader :nodes

        def initialize
          @nodes = {}
          @entries_klasses = nil
          @entries_attributes = {}
        end

        def build_factory!(entry_name, entry_klass, **entry_attributes)
          @nodes[entry_name] = build_factory(entry_name, entry_klass, entry_attributes)
        end

        def push_entries_config!(entries_klasses, **entries_attributes)
          @entries_klasses = entries_klasses
          @entries_attributes = entries_attributes
        end

        def create_entries(config, parent_node)
          create_static_entries(config, parent_node).merge(
            create_dynamic_entries(config, parent_node)
          )
        end

        private

        def create_static_entries(config, parent_node)
          return {} unless config.is_a?(Hash)

          @nodes.to_h do |node_name, node|
            [
              node_name,
              create_node(node, node_name, config[node_name], parent_node)
            ]
          end
        end

        def create_dynamic_entries(config, parent_node)
          return {} unless entries_defined?

          config.to_h do |entry_name, entry_value|
            klass = entries_klass(parent_node, entry_name, entry_value)
            next unless klass

            @entries_attributes[:metadata] = (@entries_attributes[:metadata] || {}).merge(name: entry_name)
            factory = build_factory(entry_name, klass, **@entries_attributes)

            [entry_name, create_node(factory, entry_name, entry_value, parent_node)]
          end
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def build_factory(entry_name, entry_klass, description: nil, default: nil, inherit: nil, reserved: nil, metadata: {})
          ::Gitlab::Config::Entry::Factory.new(entry_klass)
            .with(key: entry_name.to_s)
            .with(description: description && description % entry_name.to_s)
            .with(default: default)
            .with(inherit: inherit)
            .with(reserved: reserved)
            .metadata(metadata)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        def create_node(factory, key, value, parent_node)
          factory
            .value(value)
            .with(key: key, parent: parent_node).create! # rubocop: disable CodeReuse/ActiveRecord
        end

        def entries_defined?
          @entries_klasses
        end

        def entries_klass(parent_node, name = nil, config = nil)
          Array(@entries_klasses).then do |klasses|
            if klasses.one?
              klasses.first
            else
              parent_node.class.find_type(name, config)
            end
          end
        end
      end
    end
  end
end
