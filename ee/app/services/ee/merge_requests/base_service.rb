# frozen_string_literal: true

module EE
  module MergeRequests
    module BaseService
      extend ::Gitlab::Utils::Override

      override :execute_hooks
      def execute_hooks(merge_request, action = 'open', old_rev: nil, old_associations: {})
        super

        return unless project.jira_subscription_exists?

        if Atlassian::JiraIssueKeyExtractor.has_keys?(merge_request.title, merge_request.description)
          JiraConnect::SyncMergeRequestWorker.perform_async(merge_request.id)
        end
      end

      private

      attr_accessor :blocking_merge_requests_params

      override :filter_params
      def filter_params(merge_request)
        unless current_user.can?(:update_approvers, merge_request)
          params.delete(:approvals_before_merge)
          params.delete(:approver_ids)
          params.delete(:approver_group_ids)
        end

        self.params = ApprovalRules::ParamsFilteringService.new(merge_request, current_user, params).execute

        self.blocking_merge_requests_params =
          ::MergeRequests::UpdateBlocksService.extract_params!(params)

        super
      end
    end
  end
end
