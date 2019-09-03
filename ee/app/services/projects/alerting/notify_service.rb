# frozen_string_literal: true

module Projects
  module Alerting
    class NotifyService < BaseService
      include Gitlab::Utils::StrongMemoize

      def execute
        process_incident_issues if create_issue?

        true
      end

      private

      def generic_alert_endpoint_enabled?
        Feature.enabled?(:generic_alert_endpoint, project)
      end

      def incident_management_available?
        project.feature_available?(:incident_management)
      end

      def create_issue?
        incident_management_available? && generic_alert_endpoint_enabled?
      end

      def process_incident_issues
        IncidentManagement::ProcessAlertWorker
          .perform_async(project.id, parsed_payload)
      end

      def parsed_payload
        Gitlab::Alerting::NotificationPayloadParser.call(params.to_h)
      end
    end
  end
end
