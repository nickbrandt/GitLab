# frozen_string_literal: true

module StatusPage
  # Publishes content to status page by delegating to specific
  # publishing services.
  #
  # Use this service for publishing an incident to CDN synchronously.
  # To publish asynchronously use +StatusPage::TriggerPublishService+ instead.
  #
  # This services calls:
  # * StatusPage::PublishDetailsService
  # * StatusPage::PublishListService
  class PublishIncidentService
    include Gitlab::Utils::StrongMemoize

    def initialize(user:, project:, issue_id:)
      @user = user
      @project = project
      @issue_id = issue_id
    end

    def execute
      return error_permission_denied unless can_publish?
      return error_issue_not_found unless issue

      response = publish_details
      return response if response.error?

      publish_list
    end

    private

    attr_reader :user, :project, :issue_id

    def publish_details
      PublishDetailsService.new(project: project).execute(issue, user_notes)
    end

    def publish_list
      PublishListService.new(project: project).execute(issues)
    end

    def issue
      strong_memoize(:issue) { issues_finder.find_by_id(issue_id) }
    end

    def user_notes
      strong_memoize(:user_notes) do
        IncidentCommentsFinder.new(issue: issue).all
      end
    end

    def issues
      strong_memoize(:issues) { issues_finder.all }
    end

    def issues_finder
      strong_memoize(:issues_finder) do
        IncidentsFinder.new(project_id: project.id)
      end
    end

    def can_publish?
      user.can?(:publish_status_page, project)
    end

    def error_permission_denied
      error('No publish permission')
    end

    def error_issue_not_found
      error('Issue not found')
    end

    def error(message)
      ServiceResponse.error(message: message)
    end
  end
end
