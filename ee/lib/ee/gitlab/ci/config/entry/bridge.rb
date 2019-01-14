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

            ALLOWED_KEYS = %i[trigger stage allow_failure only except].freeze

            # TODO we probably need a common ancestor for a status / job
            #
            DEFAULT_ONLY_POLICY = {
              refs: %w(branches tags)
            }.freeze

            DEFAULT_EXCEPT_POLICY = {
            }.freeze

            validations do
              validates :config, allowed_keys: ALLOWED_KEYS
              validates :config, presence: true
              validates :trigger, presence: true
              validates :name, presence: true
              validates :name, type: Symbol
            end

            entry :trigger, ::EE::Gitlab::Ci::Config::Entry::Trigger,
              description: 'CI/CD Bridge downstream trigger definition.'

            entry :stage, ::Gitlab::Ci::Config::Entry::Stage,
              description: 'Pipeline stage this job will be executed into.'

            entry :only, ::Gitlab::Ci::Config::Entry::Policy,
              description: 'Refs policy this job will be executed for.'

            entry :except, ::Gitlab::Ci::Config::Entry::Policy,
              description: 'Refs policy this job will be executed for.'

            helpers(*ALLOWED_KEYS)
            attributes(*ALLOWED_KEYS)

            def name
              @metadata[:name]
            end

            def value
              { name: name,
                trigger: trigger_value,
                ignore: !!allow_failure,
                stage: stage_value,
                only: DEFAULT_ONLY_POLICY.deep_merge(only_value.to_h),
                except: DEFAULT_EXCEPT_POLICY.deep_merge(except_value.to_h) }
            end
          end
        end
      end
    end
  end
end
