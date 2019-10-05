# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a set of needs dependencies.
        #
        class Needs < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Config::Entry::Validatable

          validations do
            validates :config, presence: true

            validate do
              unless config.is_a?(Hash) || config.is_a?(Array)
                errors.add(:config, 'can only be a hash or an array')
              end
            end

            validate do
              [config].flatten.each do |need|
                if Needs.find_type(need).nil?
                  errors.add(:need, 'has an unsupported type')
                end
              end
            end
          end

          TYPES = [Entry::Need::Pipeline].freeze

          private_constant :TYPES

          def self.all_types
            TYPES
          end

          def self.find_type(config)
            self.all_types.find do |type|
              type.matching?(config)
            end
          end

          def compose!(deps = nil)
            super(deps) do
              [@config].flatten.each_with_index do |need, index|
                @entries[index] = ::Gitlab::Config::Entry::Factory.new(Entry::Need)
                  .value(need)
                  .with(key: "need", parent: self, description: "need definition.") # rubocop:disable CodeReuse/ActiveRecord
                  .create!
              end

              @entries.each_value do |entry|
                entry.compose!(deps)
              end
            end
          end

          def value
            @entries.values.group_by(&:type).transform_values do |values|
              values.map(&:value)
            end
          end
        end
      end
    end
  end
end

::Gitlab::Ci::Config::Entry::Needs.prepend_if_ee('::EE::Gitlab::Ci::Config::Entry::Needs')
