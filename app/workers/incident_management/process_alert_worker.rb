# frozen_string_literal: true

module IncidentManagement
  class ProcessAlertWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    queue_namespace :incident_management
    feature_category :incident_management

    def perform(alert_id)
      alert = find_alert(alert_id)
      return unless alert

      new_issue = create_issue_for(alert)
      return unless new_issue&.persisted?

      link_issue_with_alert(alert, new_issue.id)
    end

    private

    def find_alert(alert_id)
      AlertManagement::Alert.find_by_id(alert_id)
    end

    def parsed_payload(alert)
      Gitlab::Alerting::NotificationPayloadParser.call(alert.payload.to_h)
    end

    def create_issue_for(alert)
      IncidentManagement::CreateIssueService
        .new(alert.project, parsed_payload(alert))
        .execute
        .dig(:issue)
    end

    def link_issue_with_alert(alert, issue_id)
      return if alert.update(issue_id: issue_id)

      Gitlab::AppLogger.warn(
        message: 'Cannot link an Issue with Alert',
        issue_id: issue_id,
        alert_id: alert.id,
        alert_errors: alert.errors.messages
      )
    end
  end
end
