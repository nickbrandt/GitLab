# frozen_string_literal: true

module StatusPage
  class PublishIncidentWorker
    include ApplicationWorker
    include Gitlab::Utils::StrongMemoize

    sidekiq_options retry: 5

    feature_category :status_page
    worker_has_external_dependencies!
    idempotent!

    def perform(project_id, issue_id)
      @project_id = project_id
      @issue_id = issue_id
      @project = Project.find_by_id(project_id)
      return if project.nil?

      publish
    end

    private

    attr_reader :project_id, :issue_id, :project

    def publish
      result = PublishIncidentService
        .new(project: project, issue_id: issue_id)
        .execute

      log_error(result.message) if result.error?
    rescue => e
      log_error(e.message)
      raise
    end

    def log_error(message)
      preamble = "Failed to publish incident for project_id=#{project_id}, issue_id=#{issue_id}"
      logger.error("#{preamble}: #{message}")
    end
  end
end
