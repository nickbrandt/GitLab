# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          module Bridge
            extend ActiveSupport::Concern
            extend ::Gitlab::Utils::Override

            prepended do
              EE_ALLOWED_KEYS = %i[status].freeze

              validations do
                validate on: :composed do
                  if needs_defined? && status_defined?
                    errors.add(:config, 'should not contain both "needs" and "status" keywords')
                  end
                end
              end

              entry :status, EE::Gitlab::Ci::Config::Entry::Status,
                description: 'Mirroring the status of another project pipeline.',
                inherit: false

              attributes :status
            end

            class_methods do
              extend ::Gitlab::Utils::Override

              override :allowed_keys
              def allowed_keys
                super + EE_ALLOWED_KEYS
              end

              override :status_mirror?
              def status_mirror?(config)
                super || config.key?(:status)
              end
            end

            override :mirror_status_value
            def mirror_status_value
              { bridge: [{ pipeline: status_value[:project] }] } if status_value
            end

            override :mirror_status_config
            def mirror_status_config
              return [{ pipeline: status_value[:project] }] if status_value

              super
            end
          end
        end
      end
    end
  end
end
