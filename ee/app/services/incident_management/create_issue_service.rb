# frozen_string_literal: true

module IncidentManagement
  class CreateIssueService < BaseService
    include Gitlab::Utils::StrongMemoize

    def execute
      return error_with('setting disabled') unless incident_management_setting.create_issue?
      return error_with('invalid alert') unless alert.valid?

      success(issue: create_issue)
    end

    private

    def create_issue
      Issues::CreateService.new(
        project,
        issue_author,
        title: issue_title,
        description: issue_description
      ).execute
    end

    def issue_author
      strong_memoize(:issue_author) do
        User.alert_bot
      end
    end

    def issue_title
      alert.full_title
    end

    def issue_description
      return alert_summary unless issue_template_content

      horizontal_line = "\n---\n\n"

      alert_summary + horizontal_line + issue_template_content
    end

    def alert_summary
      alert.issue_summary_markdown
    end

    def alert
      strong_memoize(:alert) do
        Gitlab::Alerting::Alert.new(project: project, payload: params).present
      end
    end

    def issue_template_content
      incident_management_setting.issue_template_content
    end

    def incident_management_setting
      strong_memoize(:incident_management_setting) do
        project.incident_management_setting ||
          project.build_incident_management_setting
      end
    end

    def error_with(message)
      log_error(%{Cannot create incident issue for "#{project.full_name}": #{message}})

      error(message)
    end
  end
end
