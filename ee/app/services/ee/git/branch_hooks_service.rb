# frozen_string_literal: true

module EE
  module Git
    module BranchHooksService
      extend ::Gitlab::Utils::Override

      private

      override :branch_change_hooks
      def branch_change_hooks
        super

        return unless project.jira_subscription_exists?

        branch_to_sync = branch_name if Atlassian::JiraIssueKeyExtractor.has_keys?(branch_name)
        commits_to_sync = limited_commits.select { |commit| Atlassian::JiraIssueKeyExtractor.has_keys?(commit.safe_message) }.map(&:sha)

        if branch_to_sync || commits_to_sync.any?
          JiraConnect::SyncBranchWorker.perform_async(project.id, branch_to_sync, commits_to_sync)
        end
      end

      override :pipeline_options
      def pipeline_options
        mirror_update = project.mirror? &&
          project.repository.up_to_date_with_upstream?(branch_name)

        { mirror_update: mirror_update }
      end
    end
  end
end
