module EE
  module MergeRequestsHelper
    def merge_request_approver_path(project, merge_request, approver)
      params = {}
      params[:merge_request_id] = merge_request.iid if merge_request

      case approver
      when Approver
        project_approver_path(project, approver, params)
      when ApproverGroup
        project_approver_group_path(project, approver, params)
      else
        raise TypeError.new('unknown approver type')
      end
    end
  end
end
