# frozen_string_literal: true

module EE
  module MergeRequests
    module ApprovalService
      extend ::Gitlab::Utils::Override

      IncorrectApprovalPasswordError = Class.new(StandardError)

      override :execute
      def execute(merge_request)
        if incorrect_approval_password?(merge_request)
          raise IncorrectApprovalPasswordError
        end

        super
      end

      private

      override :reset_approvals_cache
      def reset_approvals_cache(merge_request)
        merge_request.reset_approval_cache!
      end

      override :execute_approval_hooks
      def execute_approval_hooks(merge_request, current_user)
        if merge_request.approvals_left.zero?
          notification_service.async.approve_mr(merge_request, current_user)
          execute_hooks(merge_request, 'approved')
        else
          execute_hooks(merge_request, 'approval')
        end
      end

      override :create_event
      def create_event(merge_request)
        # Making sure MergeRequest::Metrics updates are in sync with
        # Event creation.
        ::Event.transaction do
          event_service.approve_mr(merge_request, current_user)
          calculate_approvals_metrics(merge_request)
        end
      end

      def incorrect_approval_password?(merge_request)
        merge_request.project.require_password_to_approve? &&
          !::Gitlab::Auth.find_with_user_password(current_user.username, params[:approval_password])
      end

      def calculate_approvals_metrics(merge_request)
        return unless merge_request.project.feature_available?(:code_review_analytics)

        ::Analytics::RefreshApprovalsData.new(merge_request).execute
      end
    end
  end
end
