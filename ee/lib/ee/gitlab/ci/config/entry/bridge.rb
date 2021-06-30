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
              validations do
                validate on: :composed do
                  if needs_defined? && status_defined?
                    errors.add(:config, 'should not contain both needs and status mirror')
                  end
                end
              end

              entry :status, EE::Gitlab::Ci::Config::Entry::Status,
                description: 'Mirroring the status of another project pipeline.',
                inherit: false

              attributes :status
            end

            override :status_mirror?
            def self.status_mirror?(config)
              super || config.key?(:status)
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
