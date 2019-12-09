# frozen_string_literal: true

module EE
  module MergeRequestWidgetEntity
    include ::API::Helpers::RelatedResourcesHelpers
    extend ActiveSupport::Concern

    prepended do
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

      expose :enabled_reports do |merge_request|
        merge_request.enabled_reports
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
          expose_path(api_v4_projects_managed_licenses_path(id: merge_request.target_project.id))
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

      expose :metrics_reports_path, if: -> (mr, _) { mr.has_metrics_reports? } do |merge_request|
        metrics_reports_project_merge_request_path(merge_request.project, merge_request, format: :json)
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

      expose :create_vulnerability_feedback_issue_path do |merge_request|
        presenter(merge_request).create_vulnerability_feedback_issue_path(merge_request.project)
      end

      expose :create_vulnerability_feedback_merge_request_path do |merge_request|
        presenter(merge_request).create_vulnerability_feedback_merge_request_path(merge_request.project)
      end

      expose :create_vulnerability_feedback_dismissal_path do |merge_request|
        presenter(merge_request).create_vulnerability_feedback_dismissal_path(merge_request.project)
      end

      expose :has_approvals_available do |merge_request|
        merge_request.approval_feature_available?
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

      expose :merge_train_when_pipeline_succeeds_docs_path do |merge_request|
        presenter(merge_request).merge_train_when_pipeline_succeeds_docs_path
      end

      expose :merge_immediately_docs_path do |merge_request|
        presenter(merge_request).merge_immediately_docs_path
      end

      expose :blocking_merge_requests, if: -> (mr, _) { mr&.target_project&.feature_available?(:blocking_merge_requests) }

      private

      def blocking_merge_requests
        hidden_blocking_count = object.hidden_blocking_merge_requests_count(current_user)
        visible_mrs = object.visible_blocking_merge_requests(current_user)
        visible_mrs_by_state = visible_mrs
          .map { |mr| represent_blocking_mr(mr) }
          .group_by { |blocking_mr| blocking_mr.object.state_id_name }

        {
          total_count: visible_mrs.count + hidden_blocking_count,
          hidden_count: hidden_blocking_count,
          visible_merge_requests: visible_mrs_by_state
        }
      end
    end

    def represent_blocking_mr(blocking_mr)
      blocking_mr_options = options.merge(from_project: object.target_project)

      ::BlockingMergeRequestEntity.represent(blocking_mr, blocking_mr_options)
    end

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
