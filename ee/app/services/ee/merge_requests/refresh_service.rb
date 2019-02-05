# frozen_string_literal: true

module EE
  module MergeRequests
    module RefreshService
      extend ::Gitlab::Utils::Override

      private

      override :refresh_merge_requests!
      def refresh_merge_requests!
        update_approvers do
          super && reset_approvals_for_merge_requests(push.ref, push.newrev)
        end
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
        return yield unless project.feature_available?(:code_owners)

        if ::Feature.enabled?(:approval_rules, project)
          results = yield

          merge_requests_for_source_branch.each do |merge_request|
            ::MergeRequests::SyncCodeOwnerApprovalRules.new(merge_request).execute
          end
        else
          previous_diffs = fetch_latest_merge_request_diffs

          results = yield

          merge_requests = merge_requests_for_source_branch
          ActiveRecord::Associations::Preloader.new.preload(merge_requests, :latest_merge_request_diff) # rubocop: disable CodeReuse/ActiveRecord)

          merge_requests.each do |merge_request|
            previous_diff = previous_diffs.find { |diff| diff.merge_request == merge_request }
            previous_code_owners = ::Gitlab::CodeOwners.for_merge_request(merge_request, merge_request_diff: previous_diff)
            new_code_owners = merge_request.code_owners - previous_code_owners

            create_approvers(merge_request, new_code_owners)

            merge_request.sync_code_owners_with_approvers
          end
        end

        results
      end

      def create_approvers(merge_request, users)
        return if users.empty?
        return unless merge_request.approvers_overwritten?

        now = Time.now

        rows = users.map do |user|
          {
            target_id: merge_request.id,
            target_type: merge_request.class.name,
            user_id: user.id,
            created_at: now,
            updated_at: now
          }
        end

        ::Gitlab::Database.bulk_insert(Approver.table_name, rows)
      end
    end
  end
end
