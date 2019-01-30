# frozen_string_literal: true

module Projects
  module Prometheus
    module Alerts
      class NotifyService < BaseService
        def execute(token)
          return false unless valid_version?
          return false unless valid_alert_manager_token?(token)

          notification_service.async.prometheus_alerts_fired(project, firings) if firings.any?

          persist_events(project, current_user, params)

          true
        end

        private

        def firings
          @firings ||= alerts_by_status('firing')
        end

        def alerts_by_status(status)
          alerts.select { |alert| alert['status'] == status }
        end

        def alerts
          params['alerts']
        end

        def valid_version?
          params['version'] == '4'
        end

        def valid_alert_manager_token?(token)
          # We don't support token authorization for manual installations.
          prometheus = project.find_or_initialize_service('prometheus')
          return true if prometheus.manual_configuration?

          prometheus_application = available_prometheus_application(project)
          return false unless prometheus_application

          if token
            compare_token(token, prometheus_application.alert_manager_token)
          else
            prometheus_application.alert_manager_token.nil?
          end
        end

        def available_prometheus_application(project)
          alert_id = gitlab_alert_id
          return unless alert_id

          alert = project.prometheus_alerts.for_metric(alert_id).first
          return unless alert

          cluster = alert.environment.deployment_platform&.cluster
          return unless cluster&.enabled?
          return unless cluster.application_prometheus_available?

          cluster.application_prometheus
        end

        def gitlab_alert_id
          alerts&.first&.dig('labels', 'gitlab_alert_id')
        end

        def compare_token(expected, actual)
          return unless expected && actual

          ActiveSupport::SecurityUtils.variable_size_secure_compare(expected, actual)
        end

        def persist_events(project, current_user, params)
          CreateEventsService.new(project, current_user, params).execute
        end
      end
    end
  end
end
