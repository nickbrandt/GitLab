# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          ##
          # Entry that represents a CI/CD Bridge job that is responsible for
          # defining a downstream project trigger.
          #
          class Bridge < ::Gitlab::Config::Entry::Node
            include ::Gitlab::Config::Entry::Configurable
            include ::Gitlab::Config::Entry::Attributable
            include ::Gitlab::Config::Entry::Inheritable

            ALLOWED_KEYS = %i[trigger stage allow_failure only except
                              when extends variables needs].freeze

            validations do
              validates :config, allowed_keys: ALLOWED_KEYS
              validates :config, presence: true
              validates :name, presence: true
              validates :name, type: Symbol

              validate do
                unless trigger.present? || needs.present?
                  errors.add(:config, 'should contain either a trigger or a needs:pipeline')
                end
              end

              with_options allow_nil: true do
                validates :when,
                  inclusion: { in: %w[on_success on_failure always],
                               message: 'should be on_success, on_failure or always' }
                validates :extends, type: String
              end
            end

            entry :trigger, ::EE::Gitlab::Ci::Config::Entry::Trigger,
              description: 'CI/CD Bridge downstream trigger definition.',
              inherit: false

            entry :needs, ::EE::Gitlab::Ci::Config::Entry::Needs,
              description: 'CI/CD Bridge needs dependency definition.',
              inherit: false

            entry :stage, ::Gitlab::Ci::Config::Entry::Stage,
              description: 'Pipeline stage this job will be executed into.',
              inherit: false

            entry :only, ::Gitlab::Ci::Config::Entry::Policy,
              description: 'Refs policy this job will be executed for.',
              default: ::Gitlab::Ci::Config::Entry::Policy::DEFAULT_ONLY,
              inherit: false

            entry :except, ::Gitlab::Ci::Config::Entry::Policy,
              description: 'Refs policy this job will be executed for.',
              inherit: false

            entry :variables, ::Gitlab::Ci::Config::Entry::Variables,
              description: 'Environment variables available for this job.',
              inherit: false

            helpers(*ALLOWED_KEYS)
            attributes(*ALLOWED_KEYS)

            def self.matching?(name, config)
              ::Feature.enabled?(:cross_project_pipeline_triggers, default_enabled: true) &&
                !name.to_s.start_with?('.') &&
                config.is_a?(Hash) &&
                (config.key?(:trigger) || config.key?(:needs))
            end

            def self.visible?
              true
            end

            def name
              @metadata[:name]
            end

            def value
              { name: name,
                trigger: (trigger_value if trigger_defined?),
                needs: (needs_value if needs_defined?),
                ignore: !!allow_failure,
                stage: stage_value,
                when: when_value,
                extends: extends_value,
                variables: (variables_value if variables_defined?),
                only: only_value,
                except: except_value }.compact
            end

            private

            def overwrite_entry(deps, key, current_entry)
              deps.default[key] unless current_entry.specified?
            end
          end
        end
      end
    end
  end
end
