# frozen_string_literal: true

module Projects
  module Alerting
    class NotifyService < BaseService
      include Gitlab::Utils::StrongMemoize

      # Prevents users to use WIP feature on private GitLab instances
      # by enabling 'generic_alert_endpoint' feature manually.
      # TODO: https://gitlab.com/gitlab-org/gitlab/issues/14792
      DEV_TOKEN = :development_token

      def execute(token)
        return forbidden unless alerts_service_activated?
        return unauthorized unless valid_token?(token)

        process_incident_issues

        ServiceResponse.success
      rescue Gitlab::Alerting::NotificationPayloadParser::BadPayloadError
        bad_request
      end

      private

      def generic_alert_endpoint_enabled?
        Feature.enabled?(:generic_alert_endpoint, project)
      end

      def incident_management_available?
        project.feature_available?(:incident_management)
      end

      def alerts_service_activated?
        incident_management_available? &&
          generic_alert_endpoint_enabled? &&
          project.alerts_service.try(:active?)
      end

      def process_incident_issues
        IncidentManagement::ProcessAlertWorker
          .perform_async(project.id, parsed_payload)
      end

      def parsed_payload
        Gitlab::Alerting::NotificationPayloadParser.call(params.to_h)
      end

      def valid_token?(token)
        token == DEV_TOKEN
      end

      def bad_request
        ServiceResponse.error(message: 'Bad Request', http_status: 400)
      end

      def unauthorized
        ServiceResponse.error(message: 'Unauthorized', http_status: 401)
      end

      def forbidden
        ServiceResponse.error(message: 'Forbidden', http_status: 403)
      end
    end
  end
end
