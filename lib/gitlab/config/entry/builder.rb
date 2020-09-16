# frozen_string_literal: true
module Gitlab
  module Config
    module Entry
      class Builder
        attr_reader :nodes

        def initialize
          @nodes = {} # { <key> : <Gitlab::Config::Entry::Factory>, ... }
          @entries_factory = nil # <Gitlab::Config::Entry::Factory>
        end

        def build_factories!(entry_name, entry_klass, **entry_attributes)
          entry_attributes = entry_attributes.merge(entry_name: entry_name)
          @nodes[entry_name] = build_factory(entry_klass, entry_attributes)
        end

        def build_factory!(entries_klasses, **entries_attributes)
          return unless entries_klasses

          @entries_factory = build_factory(entries_klasses, entries_attributes)
        end

        def create_entries(config, parent_node)
          create_entries_from_nodes(config, parent_node).merge(
            create_entries_from_config(config, parent_node)
          )
        end

        private

        def create_entries_from_nodes(config, parent_node)
          return {} unless config.is_a?(Hash)

          @nodes.to_h do |entry_name, factory|
            [
              entry_name,
              create_node(factory, entry_name, config[entry_name], parent_node)
            ]
          end
        end

        def create_entries_from_config(config, parent_node)
          return {} unless @entries_factory

          config.to_h do |entry_name, entry_value|
            [
              entry_name,
              create_node(@entries_factory, entry_name, entry_value, parent_node)
            ]
          end
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def build_factory(entry_klasses, entry_name: nil, description: nil, default: nil, inherit: nil, reserved: nil, metadata: {})
          factory = ::Gitlab::Config::Entry::Factory.new(entry_klasses)
            .with(description: description)
            .with(default: default)
            .with(inherit: inherit)
            .with(reserved: reserved)
            .metadata(metadata)

          entry_name ? factory.with(key: entry_name.to_s) : factory
        end

        def create_node(factory, key, value, parent_node)
          factory
            .with(
              key: key,
              parent: parent_node,
              description: factory.description % key.to_s
            )
            .metadata(name: :key.to_s)
            .value(value).create!
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
