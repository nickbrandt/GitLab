# frozen_string_literal: true

module EE
  module MergeRequestPresenter
    include ::VisibleApprovable
    prepend VisibleApprovableForRule

    def approvals_path
      if requires_approve?
        approvals_project_merge_request_path(project, merge_request)
      end
    end

    def api_approvals_path
      if requires_approve?
        api_v4_projects_merge_requests_approvals_path(id: project.id, merge_request_iid: merge_request.iid)
      end
    end

    def api_approve_path
      if requires_approve?
        api_v4_projects_merge_requests_approve_path(id: project.id, merge_request_iid: merge_request.iid)
      end
    end

    def api_unapprove_path
      if requires_approve?
        api_v4_projects_merge_requests_unapprove_path(id: project.id, merge_request_iid: merge_request.iid)
      end
    end

    def target_project
      merge_request.target_project.present(current_user: current_user)
    end

    def approver_groups
      ::ApproverGroup.filtered_approver_groups(merge_request.approver_groups, current_user)
    end
  end
end
