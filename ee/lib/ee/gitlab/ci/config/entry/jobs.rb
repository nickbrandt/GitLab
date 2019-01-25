# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          module Jobs
            extend ::Gitlab::Utils::Override

            override :node_type
            def node_type(name)
              if bridge?(name)
                ::EE::Gitlab::Ci::Config::Entry::Bridge
              else
                super
              end
            end

            def bridge?(name)
              config.fetch(name).yield_self do |value|
                value.is_a?(Hash) && value.key?(:trigger) &&
                  cross_project_triggers_enabled?
              end
            end

            def cross_project_triggers_enabled?
              ::Feature.enabled?(:cross_project_pipeline_triggers, default_enabled: false)
            end
          end
        end
      end
    end
  end
end
