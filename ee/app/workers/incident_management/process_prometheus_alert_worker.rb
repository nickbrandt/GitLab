# frozen_string_literal: true

module IncidentManagement
  class ProcessPrometheusAlertWorker
    include ApplicationWorker

    queue_namespace :incident_management

    def perform(project_id, alert_hash)
      project = find_project(project_id)
      return unless project

      event = find_prometheus_alert_event(alert_hash)
      issue = create_issue(project, alert_hash)

      relate_issue_to_event(event, issue)
    end

    private

    def find_project(project_id)
      Project.find_by_id(project_id)
    end

    def find_prometheus_alert_event(alert_hash)
      started_at = alert_hash.dig('startsAt')
      gitlab_alert_id = alert_hash.dig('labels', 'gitlab_alert_id')
      payload_key = PrometheusAlertEvent.payload_key_for(gitlab_alert_id, started_at)

      PrometheusAlertEvent.find_by_payload_key(payload_key)
    end

    def create_issue(project, alert)
      IncidentManagement::CreateIssueService
        .new(project, alert)
        .execute
        .dig(:issue)
    end

    def relate_issue_to_event(event, issue)
      return unless event && issue

      if event.related_issues.exclude?(issue)
        event.related_issues << issue
      end
    end
  end
end
