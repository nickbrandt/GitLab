# frozen_string_literal: true

module ErrorTracking
  class ListIssuesService < ::BaseService
    DEFAULT_ISSUE_STATUS = 'unresolved'.freeze
    DEFAULT_LIMIT = 20

    def execute
      return error('not enabled') unless valid?
      return error('access denied') unless can?(current_user, :read_sentry_issue, project)

      issues = sentry_client.list_issues(issue_status: issue_status, limit: limit)
      success(issues: issues)
    end

    def external_url
      project_error_tracking_setting&.sentry_external_url
    end

    private

    def project_error_tracking_setting
      project.error_tracking_setting
    end

    def issue_status
      params[:issue_status] || DEFAULT_ISSUE_STATUS
    end

    def limit
      params[:limit] || DEFAULT_LIMIT
    end

    def valid?
      project_error_tracking_setting&.enabled?
    end

    def sentry_client
      project_error_tracking_setting&.sentry_client
    end
  end
end
