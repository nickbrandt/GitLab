# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        class Need < ::Gitlab::Config::Entry::Simplifiable
          strategy :Pipeline, if: -> (config) { config.is_a?(String) || config.is_a?(Symbol) }

          class Pipeline < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Validatable

            validations do
              validates :config, presence: true
            end

            def bridge?
              false
            end

            def pipeline?
              true
            end

            def value
              @config.to_s
            end
          end

          class UnknownStrategy < ::Gitlab::Config::Entry::Node
            def errors
              ["#{location} has to be a string or symbol"]
            end
          end
        end
      end
    end
  end
end

::Gitlab::Ci::Config::Entry::Need.prepend_if_ee('::EE::Gitlab::Ci::Config::Entry::Need') # rubocop: disable Cop/InjectEnterpriseEditionModule
::Gitlab::Ci::Config::Entry::Need::UnknownStrategy.prepend_if_ee('::EE::Gitlab::Ci::Config::Entry::Need::UnknownStrategy')
