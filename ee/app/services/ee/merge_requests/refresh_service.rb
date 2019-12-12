# frozen_string_literal: true

module EE
  module MergeRequests
    module RefreshService
      extend ::Gitlab::Utils::Override

      private

      override :refresh_merge_requests!
      def refresh_merge_requests!
        update_approvers
        reset_approvals_for_merge_requests(push.ref, push.newrev)
        check_merge_train_status

        super
      end

      # Note: Closed merge requests also need approvals reset.
      def reset_approvals_for_merge_requests(ref, newrev)
        branch_name = ::Gitlab::Git.ref_name(ref)
        merge_requests = merge_requests_for(branch_name, mr_states: [:opened, :closed])

        merge_requests.each do |merge_request|
          target_project = merge_request.target_project

          if target_project.reset_approvals_on_push &&
              merge_request.rebase_commit_sha != newrev

            merge_request.approvals.delete_all
          end
        end
      end

      # @return [Hash<Integer, MergeRequestDiff>] Diffs prior to code push, mapped from merge request id
      def fetch_latest_merge_request_diffs
        merge_requests = merge_requests_for_source_branch
        ActiveRecord::Associations::Preloader.new.preload(merge_requests, :latest_merge_request_diff) # rubocop: disable CodeReuse/ActiveRecord
        merge_requests.map(&:latest_merge_request_diff)
      end

      def update_approvers
        merge_requests_for_source_branch.each do |merge_request|
          ::MergeRequests::SyncCodeOwnerApprovalRules.new(merge_request).execute if project.feature_available?(:code_owners)
          ::MergeRequests::SyncReportApproverApprovalRules.new(merge_request).execute if project.feature_available?(:report_approver_rules)
        end
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def check_merge_train_status
        MergeTrains::CheckStatusService.new(project, current_user)
          .execute(project, @push.branch_name, @push.newrev)
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables
    end
  end
end
