module EE
  module API
    module Helpers
      module ProjectsHelpers
        extend ActiveSupport::Concern

        prepended do
          helpers do
            params :optional_project_params_ee do
              optional :repository_storage, type: String, desc: 'Which storage shard the repository is on. Available only to admins'
              optional :approvals_before_merge, type: Integer, desc: 'How many approvers should approve merge request by default'
              optional :external_authorization_classification_label, type: String, desc: 'The classification label for the project'
              optional :mirror, type: Boolean, desc: 'Enables pull mirroring in a project'
              optional :mirror_trigger_builds, type: Boolean, desc: 'Pull mirroring triggers builds'
            end
          end
        end
      end
    end
  end
end
