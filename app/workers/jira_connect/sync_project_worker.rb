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
      branches = project.repository.branches.reject do |branch|
        !branch.name.match(Gitlab::Regex.jira_issue_key_regex)
      end.compact[0..MAX_RECORDS_LIMIT - 1]

      dereferenced_targets = batch_load_dereferenced_targets(project, branches)

      branches.map do |branch|
        Gitlab::Git::Branch.new(project.repository, branch.name, branch.target, dereferenced_targets[branch.dereferenced_target.id])
      end
    end

    def batch_load_dereferenced_targets(project, branches)
      target_ids = branches.map { |branch| branch.dereferenced_target.id }

      project.repository.commits_by(oids: target_ids).index_by(&:id)
    end
  end
end
