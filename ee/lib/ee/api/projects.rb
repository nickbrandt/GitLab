# frozen_string_literal: true

module EE
  module API
    module Projects
      extend ActiveSupport::Concern

      prepended do
        resource :projects do
          desc 'Restore a project' do
            success Entities::Project
          end
          post ':id/restore' do
            authorize!(:remove_project, user_project)
            break not_found! unless user_project.feature_available?(:marking_project_for_deletion)

            result = ::Projects::RestoreService.new(user_project, current_user).execute
            if result[:status] == :success
              present user_project, with: ::API::Entities::Project, current_user: current_user
            else
              render_api_error!(result[:message], 400)
            end
          end
        end

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

          override :delete_project
          def delete_project(user_project)
            return super unless user_project.adjourned_deletion?

            result = destroy_conditionally!(user_project) do
              ::Projects::MarkForDeletionService.new(user_project, current_user, {}).execute
            end

            if result[:status] == :success
              accepted!
            else
              render_api_error!(result[:message], 400)
            end
          end
        end
      end
    end
  end
end
