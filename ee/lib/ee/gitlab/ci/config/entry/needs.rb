# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          ##
          # Entry that represents a cross-project needs dependency.
          #
          class Needs < ::Gitlab::Config::Entry::Simplifiable
            strategy :BridgeNeeds, if: -> (config) { config.is_a?(Hash) }
            strategy :ComplexNeeds, if: -> (config) { config.is_a?(Array) }

            class BridgeNeeds < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Validatable
              include ::Gitlab::Config::Entry::Attributable

              ALLOWED_KEYS = %i[pipeline].freeze
              attributes :pipeline

              validations do
                validates :config, presence: true
                validates :config, allowed_keys: ALLOWED_KEYS
                validates :pipeline, type: String, presence: true
              end
            end

            class ComplexNeeds < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Validatable

              validations do
                validates :config, presence: true
                validates :config, type: Array
                validate :one_needs_pipeline
                validate :needs_array_elements
              end

              def one_needs_pipeline
                if config.count { |element| element.is_a?(Hash) } > 1
                  errors.add(:needs, 'needs hash element needs to have a pipeline key')
                end
              end

              def needs_array_elements
                config.each do |element|
                  next if element.is_a?(String)

                  unless element.is_a?(Hash) && element[:pipeline]
                    errors.add(:needs, 'needs hash element needs to have a pipeline key')
                  end
                end
              end

              def value
                bridge, pipeline = config.partition { |element| element.is_a?(Hash) }
                { bridge: bridge.first, pipeline: pipeline }
              end
            end

            class UnknownStrategy < ::Gitlab::Config::Entry::Node
              def errors
                ["#{location} has to be either an array of conditions or a hash"]
              end
            end
          end
        end
      end
    end
  end
end
