# frozen_string_literal: true

module EE
  module API
    module Projects
      extend ActiveSupport::Concern

      prepended do
        helpers do
          extend ::Gitlab::Utils::Override

          def apply_filters(projects)
            projects = super(projects)
            projects = projects.verification_failed_wikis if params[:wiki_checksum_failed]
            projects = projects.verification_failed_repos if params[:repository_checksum_failed]

            projects
          end

          override :verify_update_project_attrs!
          def verify_update_project_attrs!(project, attrs)
            super

            verify_storage_attrs!(attrs)
            verify_mirror_attrs!(project, attrs)
          end

          def verify_storage_attrs!(attrs)
            unless current_user.admin?
              attrs.delete(:repository_storage)
            end
          end

          def verify_mirror_attrs!(project, attrs)
            unless can?(current_user, :admin_mirror, project)
              attrs.delete(:mirror)
              attrs.delete(:mirror_user_id)
              attrs.delete(:mirror_trigger_builds)
              attrs.delete(:only_mirror_protected_branches)
              attrs.delete(:mirror_overwrites_diverged_branches)
              attrs.delete(:import_data_attributes)
            end
          end
        end
      end
    end
  end
end
