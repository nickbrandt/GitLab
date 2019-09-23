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
              [].tap { |array| array.push(@config) }.flatten.each_with_index do |need, index|
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
            {}.tap do |result_hash|
              result_hash[:bridge] = bridge_values.first if bridge_values.any?
              result_hash[:pipeline] = pipeline_values if pipeline_values.any?
            end
          end

          private

          def bridge_values
            @entries.values.select(&:bridge?).map(&:value)
          end

          def pipeline_values
            @entries.values.select(&:pipeline?).map(&:value)
          end
        end
      end
    end
  end
end
