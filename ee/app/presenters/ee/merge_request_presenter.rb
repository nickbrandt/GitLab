# frozen_string_literal: true

module EE
  module MergeRequestPresenter
    include ::VisibleApprovable
    include ::EE::ProjectsHelper # rubocop: disable Cop/InjectEnterpriseEditionModule

    def approvals_path
      if expose_mr_approval_path?
        expose_path(approvals_project_merge_request_path(project, merge_request))
      end
    end

    def api_approvals_path
      if expose_mr_approval_path?
        expose_path(api_v4_projects_merge_requests_approvals_path(id: project.id, merge_request_iid: merge_request.iid))
      end
    end

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

    def api_approve_path
      if expose_mr_approval_path?
        expose_path(api_v4_projects_merge_requests_approve_path(id: project.id, merge_request_iid: merge_request.iid))
      end
    end

    def api_unapprove_path
      if expose_mr_approval_path?
        expose_path(api_v4_projects_merge_requests_unapprove_path(id: project.id, merge_request_iid: merge_request.iid))
      end
    end

    def merge_train_when_pipeline_succeeds_docs_path
      help_page_path('ci/merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md', anchor: 'startadd-to-merge-train-when-pipeline-succeeds')
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

    private

    def expose_mr_approval_path?
      approval_feature_available? && merge_request.iid
    end
  end
end
