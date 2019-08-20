# frozen_string_literal: true

module API
  class MergeRequestApprovalRules < ::Grape::API
    params do
      requires :id, type: String, desc: 'The ID of a project'
      requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
    end
    resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      segment ':id/merge_requests/:merge_request_iid/approval_rules' do
        desc 'Get all merge request approval rules' do
          success EE::API::Entities::MergeRequestApprovalRule
        end
        get do
          merge_request = find_merge_request_with_access(params[:merge_request_iid])

          present merge_request.approval_rules, with: EE::API::Entities::MergeRequestApprovalRule, current_user: current_user
        end
      end
    end
  end
end
