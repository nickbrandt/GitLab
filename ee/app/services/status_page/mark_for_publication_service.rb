# frozen_string_literal: true

module StatusPage
  # Marks an issue as published.
  class MarkForPublicationService
    def initialize(project, user, issue)
      @project = project
      @user = user
      @issue = issue
    end

    def execute
      return unless status_page_enabled?
      return unless can_publish?
      return unless publishable_issue?

      track_incident
      add_system_note
    end

    private

    attr_reader :user, :project, :issue

    def can_publish?
      user&.can?(:mark_issue_for_publication, project)
    end

    def status_page_enabled?
      project.status_page_setting&.enabled?
    end

    def publishable_issue?
      !issue.confidential? &&
        !issue.status_page_published_incident
    end

    def add_system_note
      ::SystemNoteService.publish_issue_to_status_page(issue, project, user)
    end

    def track_incident
      PublishedIncident.track(issue)
    end
  end
end
