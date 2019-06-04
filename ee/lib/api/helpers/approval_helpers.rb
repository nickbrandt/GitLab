# frozen_string_literal: true

module API
  module Helpers
    module ApprovalHelpers
      def present_approval(merge_request)
        present merge_request.approval_state, with: ::EE::API::Entities::ApprovalState, current_user: current_user
      end
    end
  end
end
