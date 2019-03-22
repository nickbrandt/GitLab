# frozen_string_literal: true

module EE
  module API
    module Helpers
      module ProjectsHelpers
        extend ActiveSupport::Concern

        class_methods do
          # We don't use "override" here as this module is included into various
          # API classes, and for reasons unknown the override would be verified
          # in the context of the including class, and not in the context of
          # `API::Helpers::ProjectsHelpers`.
          #
          # Likely this is related to
          # https://gitlab.com/gitlab-org/gitlab-ce/issues/50911.
          def update_params_at_least_one_of
            super.concat [
              :approvals_before_merge,
              :repository_storage,
              :external_authorization_classification_label,
              :import_url,
              :packages_enabled,
              :fallback_approvals_required
            ]
          end
        end
      end
    end
  end
end
