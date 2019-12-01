# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          module Need
            extend ActiveSupport::Concern

            prepended do
              strategy :BridgeHash,
                class: EE::Gitlab::Ci::Config::Entry::Need::BridgeHash,
                if: -> (config) { config.is_a?(Hash) && !config.key?(:job) }
            end

            class BridgeHash < ::Gitlab::Config::Entry::Node
              include ::Gitlab::Config::Entry::Validatable
              include ::Gitlab::Config::Entry::Attributable

              ALLOWED_KEYS = %i[pipeline].freeze
              attributes :pipeline

              validations do
                validates :config, presence: true
                validates :config, allowed_keys: ALLOWED_KEYS
                validates :pipeline, type: String, presence: true
              end

              def type
                :bridge
              end
            end
          end
        end
      end
    end
  end
end
