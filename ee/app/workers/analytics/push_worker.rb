# frozen_string_literal: true

module Analytics
  class PushWorker
    include ApplicationWorker

    queue_namespace :analytics
    feature_category :code_analytics

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(project_id, oldrev, newrev)
      project = Project.find_by(id: project_id)
      return false unless project
      return false unless project.feature_available?(::Gitlab::Analytics::CODE_ANALYTICS_FEATURE_FLAG)

      project.repository.commits_between(oldrev, newrev).each do |commit|
        ::Analytics::CodeAnalytics::CommitWorker.perform_async(project.id, commit.sha)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
