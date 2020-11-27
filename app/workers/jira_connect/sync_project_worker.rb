# frozen_string_literal: true

module JiraConnect
  class SyncProjectWorker
    include ApplicationWorker

    queue_namespace :jira_connect
    feature_category :integrations
    idempotent!
    worker_has_external_dependencies!

    MAX_RECORDS_LIMIT = 400

    def perform(project_id, update_sequence_id)
      project = Project.find_by_id(project_id)

      return if project.nil?

      JiraConnect::SyncService.new(project).execute(
        merge_requests: merge_requests_to_sync(project),
        branches: branches_to_sync(project),
        update_sequence_id: update_sequence_id
      )
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def merge_requests_to_sync(project)
      project.merge_requests.with_jira_issue_keys.preload(:author).limit(MAX_RECORDS_LIMIT).order(id: :desc)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def branches_to_sync(project)
      project.repository.branch_names.map do |branch_name|
        project.repository.find_branch(branch_name) if branch_name.match(Gitlab::Regex.jira_issue_key_regex)
      end.compact[0..MAX_RECORDS_LIMIT]
    end
  end
end
