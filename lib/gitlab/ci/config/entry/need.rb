# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Need < ::Gitlab::Config::Entry::Simplifiable
          strategy :Pipeline, if: -> (config) { config.is_a?(String) }

          class Pipeline < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            validations do
              validates :config, presence: true
              validates :config, type: String
            end

            def self.matching?(config)
              config.is_a?(String)
            end

            def type
              :pipeline
            end

            def value
              { name: @config }
            end
          end

          class UnknownStrategy < ::Gitlab::Config::Entry::Node
          end
        end
      end
    end
  end
end

::Gitlab::Ci::Config::Entry::Need.prepend_if_ee('::EE::Gitlab::Ci::Config::Entry::Need')
