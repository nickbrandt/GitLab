# frozen_string_literal: true

module EE
  module MergeRequestWidgetEntity
    include ::API::Helpers::RelatedResourcesHelpers
    extend ActiveSupport::Concern

    prepended do
      expose :approvals_required, as: :approvals_before_merge

      expose :blob_path do
        expose :head_path, if: -> (mr, _) { mr.head_pipeline_sha } do |merge_request|
          project_blob_path(merge_request.project, merge_request.head_pipeline_sha)
        end

        expose :base_path, if: -> (mr, _) { mr.base_pipeline_sha } do |merge_request|
          project_blob_path(merge_request.project, merge_request.base_pipeline_sha)
        end
      end

      expose :codeclimate, if: -> (mr, _) { head_pipeline_downloadable_path_for_report_type(:codequality) } do
        expose :head_path do |merge_request|
          head_pipeline_downloadable_path_for_report_type(:codequality)
        end

        expose :base_path do |merge_request|
          base_pipeline_downloadable_path_for_report_type(:codequality)
        end
      end

      expose :performance, if: -> (mr, _) { head_pipeline_downloadable_path_for_report_type(:performance) } do
        expose :head_path do |merge_request|
          head_pipeline_downloadable_path_for_report_type(:performance)
        end

        expose :base_path do |merge_request|
          base_pipeline_downloadable_path_for_report_type(:performance)
        end
      end

      expose :sast, if: -> (mr, _) { head_pipeline_downloadable_path_for_report_type(:sast) } do
        expose :head_path do |merge_request|
          head_pipeline_downloadable_path_for_report_type(:sast)
        end

        expose :base_path do |merge_request|
          base_pipeline_downloadable_path_for_report_type(:sast)
        end
      end

      expose :dependency_scanning, if: -> (mr, _) { head_pipeline_downloadable_path_for_report_type(:dependency_scanning) } do
        expose :head_path do |merge_request|
          head_pipeline_downloadable_path_for_report_type(:dependency_scanning)
        end

        expose :base_path do |merge_request|
          base_pipeline_downloadable_path_for_report_type(:dependency_scanning)
        end
      end

      expose :license_management, if: -> (mr, _) { head_pipeline_downloadable_path_for_report_type(:license_management) } do
        expose :head_path do |merge_request|
          head_pipeline_downloadable_path_for_report_type(:license_management)
        end

        expose :base_path do |merge_request|
          base_pipeline_downloadable_path_for_report_type(:license_management)
        end

        expose :managed_licenses_path do |merge_request|
          api_v4_projects_managed_licenses_path(id: merge_request.target_project.id)
        end

        expose :can_manage_licenses do |merge_request|
          can?(current_user, :admin_software_license_policy, merge_request)
        end

        expose :license_management_settings_path, if: -> (mr, _) { can?(current_user, :admin_software_license_policy, mr.target_project) } do |merge_request|
          license_management_settings_path(merge_request.target_project)
        end

        expose :license_management_full_report_path, if: -> (mr, _) { mr.head_pipeline } do |merge_request|
          licenses_project_pipeline_path(merge_request.target_project, merge_request.head_pipeline)
        end
      end

      expose :sast_container, if: -> (mr, _) { head_pipeline_downloadable_path_for_report_type(:container_scanning) } do
        expose :head_path do |merge_request|
          head_pipeline_downloadable_path_for_report_type(:container_scanning)
        end

        expose :base_path do |merge_request|
          base_pipeline_downloadable_path_for_report_type(:container_scanning)
        end
      end

      expose :dast, if: -> (mr, _) { head_pipeline_downloadable_path_for_report_type(:dast) } do
        expose :head_path do |merge_request|
          head_pipeline_downloadable_path_for_report_type(:dast)
        end

        expose :base_path do |merge_request|
          base_pipeline_downloadable_path_for_report_type(:dast)
        end
      end

      expose :pipeline_id, if: -> (mr, _) { mr.head_pipeline } do |merge_request|
        merge_request.head_pipeline.id
      end

      expose :vulnerability_feedback_path do |merge_request|
        project_vulnerability_feedback_index_path(merge_request.project)
      end

      expose :can_create_feedback do |merge_request|
        can?(current_user, :admin_vulnerability_feedback, merge_request)
      end

      expose :rebase_commit_sha
      expose :rebase_in_progress?, as: :rebase_in_progress

      expose :can_push_to_source_branch do |merge_request|
        presenter(merge_request).can_push_to_source_branch?
      end
      expose :rebase_path do |merge_request|
        presenter(merge_request).rebase_path
      end
      expose :approvals_path do |merge_request|
        presenter(merge_request).approvals_path
      end
      expose :api_approvals_path do |merge_request|
        presenter(merge_request).api_approvals_path
      end
      expose :api_approval_settings_path do |merge_request|
        presenter(merge_request).api_approval_settings_path
      end
      expose :api_approve_path do |merge_request|
        presenter(merge_request).api_approve_path
      end
      expose :api_unapprove_path do |merge_request|
        presenter(merge_request).api_unapprove_path
      end
    end

    private

    def head_pipeline_downloadable_path_for_report_type(file_type)
      object.head_pipeline&.present(current_user: current_user)
        &.downloadable_path_for_report_type(file_type)
    end

    def base_pipeline_downloadable_path_for_report_type(file_type)
      object.base_pipeline&.present(current_user: current_user)
        &.downloadable_path_for_report_type(file_type)
    end
  end
end
