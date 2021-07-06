# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Entry
        ##
        # Entry that represents a CI/CD Bridge job that is responsible for
        # defining a downstream project trigger.
        #
        class Bridge < ::Gitlab::Config::Entry::Node
          include ::Gitlab::Ci::Config::Entry::Processable

          ALLOWED_WHEN = %w[on_success on_failure always manual].freeze
          ALLOWED_KEYS = %i[trigger parallel].freeze

          validations do
            validates :config, allowed_keys: Bridge.allowed_keys

            with_options allow_nil: true do
              validates :when, inclusion: {
                in: ALLOWED_WHEN,
                message: "should be one of: #{ALLOWED_WHEN.join(', ')}"
              }
              validates :allow_failure, boolean: true
            end

            validate on: :composed do
              unless trigger_defined? || mirror_status_config.present?
                errors.add(:config, 'should contain one of the keywords; trigger, status or needs:pipeline')
              end
            end

            validate on: :composed do
              next unless mirror_status_config.present?
              next if mirror_status_config.one?

              errors.add(:config, 'should contain at most one bridge need')
            end
          end

          entry :trigger, ::Gitlab::Ci::Config::Entry::Trigger,
            description: 'CI/CD Bridge downstream trigger definition.',
            inherit: false

          entry :needs, ::Gitlab::Ci::Config::Entry::Needs,
            description: 'CI/CD Bridge needs dependency definition.',
            inherit: false,
            metadata: { allowed_needs: %i[job bridge] }

          entry :parallel, Entry::Product::Parallel,
            description: 'Parallel configuration for this job.',
            inherit: false,
            metadata: { allowed_strategies: %i(matrix) }

          attributes :when, :allow_failure, :parallel

          def self.matching?(name, config)
            !name.to_s.start_with?('.') &&
              config.is_a?(Hash) &&
              (trigger?(config) || status_mirror?(config))
          end

          def self.visible?
            true
          end

          def self.trigger?(config)
            config.key?(:trigger)
          end

          def self.status_mirror?(config)
            # Deprecated. Will be removed: https://gitlab.com/gitlab-org/gitlab/-/issues/335081
            config.key?(:needs)
          end

          def self.allowed_keys
            ALLOWED_KEYS + PROCESSABLE_ALLOWED_KEYS
          end

          def value
            super.merge(
              trigger: (trigger_value if trigger_defined?),
              needs: needs_defined? ? needs_value : mirror_status_value,
              ignore: ignored?,
              when: self.when,
              scheduling_type: trigger_defined? && needs_defined? ? :dag : :stage,
              parallel: has_parallel? ? parallel_value : nil
            ).compact
          end

          def ignored?
            allow_failure.nil? ? manual_action? : allow_failure
          end

          # Overridden in EE
          def mirror_status_value; end

          def mirror_status_config
            needs_value[:bridge] if needs_value
          end
        end
      end
    end
  end
end

::Gitlab::Ci::Config::Entry::Bridge.prepend_mod_with('Gitlab::Ci::Config::Entry::Bridge')
