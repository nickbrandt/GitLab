# frozen_string_literal: true

module EE
  module MergeRequestPresenter
    include ::VisibleApprovable
    extend ::Gitlab::Utils::Override

    APPROVALS_WIDGET_FULL_TYPE = 'full'

    def api_approval_settings_path
      if expose_mr_approval_path?
        expose_path(api_v4_projects_merge_requests_approval_settings_path(id: project.id, merge_request_iid: merge_request.iid))
      end
    end

    def api_project_approval_settings_path
      if approval_feature_available?
        expose_path(api_v4_projects_approval_settings_path(id: project.id))
      end
    end

    def api_status_checks_path
      if expose_mr_status_checks?
        expose_path(api_v4_projects_merge_requests_status_checks_path(id: project.id, merge_request_iid: merge_request.iid))
      end
    end

    def merge_train_when_pipeline_succeeds_docs_path
      help_page_path('ci/merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md', anchor: 'add-a-merge-request-to-a-merge-train')
    end

    def merge_immediately_docs_path
      help_page_path('ci/merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md', anchor: 'immediately-merge-a-merge-request-with-a-merge-train')
    end

    def target_project
      merge_request.target_project.present(current_user: current_user)
    end

    def code_owner_rules_with_users
      @code_owner_rules ||= merge_request.approval_rules.code_owner.with_users.to_a
    end

    def approver_groups
      ::ApproverGroup.filtered_approver_groups(merge_request.approver_groups, current_user)
    end

    def suggested_approvers
      merge_request.approval_state.suggested_approvers(current_user: current_user)
    end

    override :approvals_widget_type
    def approvals_widget_type
      expose_mr_approval_path? ? APPROVALS_WIDGET_FULL_TYPE : super
    end

    def missing_security_scan_types
      merge_request.missing_security_scan_types if expose_missing_security_scan_types?
    end

    def discover_project_security_path
      project_security_discover_path(project) if show_discover_project_security?(project)
    end

    def issue_keys
      Atlassian::JiraIssueKeyExtractor.new(merge_request.title, merge_request.description).issue_keys
    end

    private

    def expose_mr_status_checks?
      ::Feature.enabled?(:ff_external_status_checks, project, default_enabled: :yaml) &&
        current_user.present? &&
        project.external_status_checks.any?
    end

    def expose_mr_approval_path?
      approval_feature_available? && merge_request.iid
    end

    def expose_missing_security_scan_types?
      ::Feature.enabled?(:missing_mr_security_scan_types, project) &&
        can?(current_user, :read_pipeline, merge_request.actual_head_pipeline)
    end
  end
end

EE::MergeRequestPresenter.include_mod_with('ProjectsHelper')
