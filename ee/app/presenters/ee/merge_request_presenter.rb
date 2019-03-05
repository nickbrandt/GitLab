# frozen_string_literal: true

module EE
  module MergeRequestPresenter
    include ::VisibleApprovable
    prepend VisibleApprovableForRule

    def approvals_path
      if approval_feature_available?
        approvals_project_merge_request_path(project, merge_request)
      end
    end

    def api_approvals_path
      if approval_feature_available?
        api_v4_projects_merge_requests_approvals_path(id: project.id, merge_request_iid: merge_request.iid)
      end
    end

    def api_approval_settings_path
      if approval_feature_available?
        api_v4_projects_merge_requests_approval_settings_path(id: project.id, merge_request_iid: merge_request.iid)
      end
    end

    def api_approve_path
      if approval_feature_available?
        api_v4_projects_merge_requests_approve_path(id: project.id, merge_request_iid: merge_request.iid)
      end
    end

    def api_unapprove_path
      if approval_feature_available?
        api_v4_projects_merge_requests_unapprove_path(id: project.id, merge_request_iid: merge_request.iid)
      end
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
  end
end
