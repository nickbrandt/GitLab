# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          ##
          # Entry that represents a cross-project downstream trigger.
          #
          class Trigger < ::Gitlab::Config::Entry::Simplifiable
            strategy :SimpleTrigger, if: -> (config) { config.is_a?(String) }
            strategy :ComplexTrigger, if: -> (config) { config.is_a?(Hash) }

            class SimpleTrigger < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Validatable

              validations { validates :config, presence: true }

              def value
                { project: @config }
              end
            end

            class ComplexTrigger < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Validatable
              include ::Gitlab::Config::Entry::Attributable

              ALLOWED_KEYS = %i[project branch strategy].freeze
              attributes :project, :branch, :strategy

              validations do
                validates :config, presence: true
                validates :config, allowed_keys: ALLOWED_KEYS
                validates :project, presence: true
                validates :branch, type: String, allow_nil: true
                validates :strategy, type: String, inclusion: { in: %w[depend], message: 'should be depend' }, allow_nil: true
              end
            end

            class UnknownStrategy < ::Gitlab::Config::Entry::Node
              def errors
                ["#{location} has to be either a string or a hash"]
              end
            end
          end
        end
      end
    end
  end
end
