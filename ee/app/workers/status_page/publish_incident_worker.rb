# frozen_string_literal: true

module StatusPage
  class PublishIncidentWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize

    sidekiq_options retry: 5

    feature_category :status_page
    worker_has_external_dependencies!
    idempotent!

    def perform(user_id, project_id, issue_id)
      @user_id = user_id
      @project_id = project_id
      @issue_id = issue_id

      return unless user && project

      publish
    end

    private

    attr_reader :user_id, :project_id, :issue_id

    def publish
      result = PublishIncidentService
        .new(user: user, project: project, issue_id: issue_id)
        .execute

      log_error(result.message) if result.error?
    rescue => e
      log_error(e.message)
      raise
    end

    def user
      strong_memoize(:user) { User.find_by_id(user_id) }
    end

    def project
      strong_memoize(:project) { Project.find_by_id(project_id) }
    end

    def log_error(message)
      preamble = "Failed to publish incident for project_id=#{project_id}, issue_id=#{issue_id}"
      logger.error("#{preamble}: #{message}")
    end
  end
end
