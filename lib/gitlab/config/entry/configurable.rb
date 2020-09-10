# frozen_string_literal: true

module Gitlab
  module Config
    module Entry
      ##
      # This mixin is responsible for adding DSL, which purpose is to
      # simplify the process of adding child nodes.
      #
      # This can be used only if parent node is a configuration entry that
      # holds a hash as a configuration value, for example:
      #
      # job:
      #   script: ...
      #   artifacts: ...
      #
      # Use `entry` to configure descendant entry nodes with explicit keys that do not vary per instance
      #  for example:
      #
      #   entry :default, Entry::Default,
      #       description: 'Default configuration for all jobs.',
      #       default: {}
      #
      # Use `entries` to configure descendant entry nodes where keys vary per instance
      #  for example:
      #
      #   entries [Entry::Hidden, Entry::Job, Entry::Bridge],
      #       description: "%s job definition."
      #
      #  The first argument can be an Entry class or an array of classes but when multiple classes are passed
      #  The parent class needs to implement a class method to find the correct class based on name and config, for example:
      #
      # def self.find_type(name, config)
      #   # Finder logic here
      # end

      module Configurable
        extend ActiveSupport::Concern

        included do
          include Validatable

          validations do
            validates :config, type: Hash, unless: :skip_config_hash_validation?
          end
        end

        def compose!(deps = nil)
          return unless valid?

          super do
            built_entries = self.class.builder.create_entries(config, self)
            entries.merge!(built_entries)

            yield if block_given?

            entries.each_value do |entry|
              entry.compose!(deps)
            end
          end
        end

        def skip_config_hash_validation?
          false
        end

        class_methods do
          include Gitlab::Utils::StrongMemoize

          def nodes
            return {} unless builder.nodes

            builder.nodes.transform_values(&:dup)
          end

          def reserved_node_names
            self.nodes.select { |_, node| node.reserved? }.keys
          end

          def builder
            strong_memoize(:builder) do
              ::Gitlab::Config::Entry::Builder.new
            end
          end

          private

          def entry(entry_name, entry_klass, entry_attributes = {})
            entry_name = entry_name.to_sym

            builder.build_factory!(entry_name, entry_klass, entry_attributes)

            helpers(entry_name)
          end

          # For use when config is a hash with arbitrary keys
          def entries(entries_klasses, **entries_attributes)
            builder.push_entries_config!(entries_klasses, entries_attributes)
          end

          def dynamic_helpers(*entry_names)
            helpers(*entry_names, dynamic: true)
          end

          def helpers(*entry_names, dynamic: false)
            entry_names.each do |entry_name|
              if method_defined?("#{entry_name}_defined?") || method_defined?("#{entry_name}_entry") || method_defined?("#{entry_name}_value")
                raise ArgumentError, "Method '#{entry_name}_defined?', '#{entry_name}_entry' or '#{entry_name}_value' already defined in '#{name}'"
              end

              unless builder.nodes[entry_name]
                raise ArgumentError, "Entry for #{entry_name} is undefined" unless dynamic
              end

              define_method("#{entry_name}_defined?") do
                entries[entry_name]&.specified?
              end

              define_method("#{entry_name}_entry") do
                entries[entry_name]
              end

              define_method("#{entry_name}_value") do
                entry = entries[entry_name]
                entry.value if entry&.valid?
              end
            end
          end
        end
      end
    end
  end
end
