# frozen_string_literal: true

module MergeRequests
  class ApprovalService < MergeRequests::BaseService
    IncorrectApprovalPasswordError = Class.new(StandardError)

    def execute(merge_request)
      if incorrect_approval_password?(merge_request)
        raise IncorrectApprovalPasswordError
      end

      approval = merge_request.approvals.new(user: current_user)

      if save_approval(approval)
        merge_request.reset_approval_cache!

        create_approval_note(merge_request)
        mark_pending_todos_as_done(merge_request)
        calculate_approvals_metrics(merge_request)

        if merge_request.approvals_left.zero?
          notification_service.async.approve_mr(merge_request, current_user)
          execute_hooks(merge_request, 'approved')
        else
          execute_hooks(merge_request, 'approval')
        end
      end
    end

    private

    def incorrect_approval_password?(merge_request)
      merge_request.project.require_password_to_approve? &&
        !Gitlab::Auth.find_with_user_password(current_user.username, params[:approval_password])
    end

    def save_approval(approval)
      Approval.safe_ensure_unique do
        approval.save
      end
    end

    def create_approval_note(merge_request)
      SystemNoteService.approve_mr(merge_request, current_user)
    end

    def mark_pending_todos_as_done(merge_request)
      todo_service.mark_pending_todos_as_done(merge_request, current_user)
    end

    def calculate_approvals_metrics(merge_request)
      return unless merge_request.project.feature_available?(:code_review_analytics)

      ::Analytics::RefreshApprovalsData.new(merge_request).execute_async
    end
  end
end
