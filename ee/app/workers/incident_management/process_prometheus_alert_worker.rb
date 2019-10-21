# frozen_string_literal: true

module IncidentManagement
  class ProcessPrometheusAlertWorker
    include ApplicationWorker

    queue_namespace :incident_management
    feature_category :incident_management

    def perform(project_id, alert_hash)
      project = find_project(project_id)
      return unless project

      parsed_alert = Gitlab::Alerting::Alert.new(project: project, payload: alert_hash)
      event = find_prometheus_alert_event(parsed_alert)
      issue = create_issue(project, alert_hash)

      relate_issue_to_event(event, issue)
    end

    private

    def find_project(project_id)
      Project.find_by_id(project_id)
    end

    def find_prometheus_alert_event(alert)
      if alert.gitlab_managed?
        find_gitlab_managed_event(alert)
      else
        find_self_managed_event(alert)
      end
    end

    def find_gitlab_managed_event(alert)
      payload_key = PrometheusAlertEvent.payload_key_for(alert.metric_id, alert.starts_at_raw)

      PrometheusAlertEvent.find_by_payload_key(payload_key)
    end

    def find_self_managed_event(alert)
      payload_key = SelfManagedPrometheusAlertEvent.payload_key_for(alert.starts_at_raw, alert.title, alert.full_query)

      SelfManagedPrometheusAlertEvent.find_by_payload_key(payload_key)
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
