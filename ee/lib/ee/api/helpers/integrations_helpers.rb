# frozen_string_literal: true

module EE
  module API
    module Helpers
      module IntegrationsHelpers
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :integrations
          def integrations
            super.merge(
              'github' => [
                {
                  required: true,
                  name: :token,
                  type: String,
                  desc: 'GitHub API token with repo:status OAuth scope'
                },
                {
                  required: true,
                  name: :repository_url,
                  type: String,
                  desc: "GitHub repository URL"
                },
                {
                  required: false,
                  name: :static_context,
                  type: ::API::Services::Boolean,
                  desc: 'Append instance name instead of branch to status check name'
                }
              ]
            )
          end

          override :integration_classes
          def integration_classes
            [
              ::Integrations::Github,
              *super
            ]
          end
        end
      end
    end
  end
end
