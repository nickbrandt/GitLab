# frozen_string_literal: true

module ErrorTracking
  class IssueUpdateService < ErrorTracking::BaseService
    private

    def perform
      response = fetch

      update_related_issue unless parse_errors(response).present?

      response
    end

    def fetch
      project_error_tracking_setting.update_issue(
        issue_id: params[:issue_id],
        params: update_params
      )
    end

    def update_related_issue
      issue = related_issue
      return unless issue && resolving?

      processed_issue = close_issue(issue)
      create_system_note(processed_issue)
    end

    def close_issue(issue)
      Issues::CloseService
        .new(project, current_user)
        .execute(issue, system_note: false)
    end

    def create_system_note(issue)
      return unless issue.reset.closed?

      SystemNoteService.close_after_error_tracking_resolve(issue, project, current_user)
    end

    def related_issue
      SentryIssuesFinder
        .new(project, current_user)
        .find_by_identifier(params[:issue_id])
        &.issue
    end

    def resolving?
      update_params[:status] == 'resolved'
    end

    def update_params
      params.except(:issue_id)
    end

    def parse_response(response)
      { updated: response[:updated].present? }
    end
  end
end
