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
