# frozen_string_literal: true

module StatusPage
  # Triggers a background job to publish of incidents to the status page.
  #
  # Use this service when issues/notes/emoji have changed to kickoff the
  # publish process.
  class TriggerPublishService
    def initialize(user:, project:)
      @user = user
      @project = project
    end

    def execute(issue_id)
      return unless can_publish?
      return unless status_page_enabled?

      StatusPage::PublishIncidentWorker.perform_async(project.id, issue_id)
    end

    private

    attr_reader :user, :project

    def can_publish?
      user.can?(:publish_status_page, project)
    end

    def status_page_enabled?
      project.status_page_setting&.enabled?
    end
  end
end
