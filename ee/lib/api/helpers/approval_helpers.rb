# frozen_string_literal: true

module API
  module Helpers
    module ApprovalHelpers
      def present_approval(merge_request)
        if Feature.enabled?(:approval_rules, merge_request.project)
          present merge_request.approval_state, with: ::EE::API::Entities::ApprovalState, current_user: current_user
        else
          present merge_request.present(current_user: current_user), with: ::EE::API::Entities::MergeRequestApprovals, current_user: current_user
        end
      end
    end
  end
end
