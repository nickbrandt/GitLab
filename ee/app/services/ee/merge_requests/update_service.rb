# frozen_string_literal: true

module EE
  module MergeRequests
    module UpdateService
      extend ::Gitlab::Utils::Override

      include CleanupApprovers

      override :execute
      def execute(merge_request)
        unless update_task_event?
          should_remove_old_approvers = params.delete(:remove_old_approvers)
          old_approvers = merge_request.overall_approvers(exclude_code_owners: true)
        end

        merge_request = super(merge_request)
        sync_approval_rules(merge_request)

        if should_remove_old_approvers && merge_request.valid?
          cleanup_approvers(merge_request, reload: true)
        end

        merge_request.reset_approval_cache!

        return merge_request if update_task_event?

        new_approvers = merge_request.overall_approvers(exclude_code_owners: true) - old_approvers

        if new_approvers.any?
          todo_service.add_merge_request_approvers(merge_request, new_approvers)
          notification_service.add_merge_request_approvers(merge_request, new_approvers, current_user)
        end

        merge_request
      end

      private

      override :create_branch_change_note
      def create_branch_change_note(merge_request, branch_type, old_branch, new_branch)
        super

        reset_approvals(merge_request)
      end

      def reset_approvals(merge_request)
        target_project = merge_request.target_project

        merge_request.approvals.delete_all if target_project.reset_approvals_on_push
      end

      # TODO remove after #1979 is closed
      def sync_approval_rules(merge_request)
        return if ::Feature.enabled?(:approval_rules, merge_request.target_project)
        return if merge_request.merged?
        return unless merge_request.previous_changes.include?(:approvals_before_merge)

        approvals_required = merge_request.approvals_before_merge || merge_request.target_project.approvals_before_merge
        merge_request.approval_rules.regular.update_all(approvals_required: approvals_required)
      end
    end
  end
end
