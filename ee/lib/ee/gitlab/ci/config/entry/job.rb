# frozen_string_literal: true

module EE
  module Gitlab
    module Ci
      module Config
        module Entry
          module Job
            extend ActiveSupport::Concern
            extend ::Gitlab::Utils::Override

            prepended do
              attributes :secrets

              validations do
                validates :secrets, absence: { message: 'feature is disabled' }, unless: :secrets_enabled?
              end

              entry :secrets, ::Gitlab::Ci::Config::Entry::Secrets,
                description: 'Configured secrets for this job',
                inherit: false
            end

            override :value
            def value
              super.merge({ secrets: secrets_value }.compact)
            end

            def secrets_enabled?
              ::Gitlab::Ci::Features.secrets_syntax_enabled?
            end
          end
        end
      end
    end
  end
end
