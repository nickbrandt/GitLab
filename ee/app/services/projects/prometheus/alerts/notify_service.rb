# frozen_string_literal: true

module Projects
  module Prometheus
    module Alerts
      class NotifyService < BaseService
        include Gitlab::Utils::StrongMemoize

        def execute(token)
          return false unless valid_payload_size?
          return false unless valid_version?
          return false unless valid_alert_manager_token?(token)

          persist_events
          send_alert_email if send_email?
          process_incident_issues if process_issues?

          true
        end

        private

        def valid_payload_size?
          Gitlab::Utils::DeepSize.new(params).valid?
        end

        def incident_management_available?
          project.feature_available?(:incident_management)
        end

        def incident_management_setting
          strong_memoize(:incident_management_setting) do
            project.incident_management_setting ||
              project.build_incident_management_setting
          end
        end

        def send_email?
          # Send email if the `incident_management` feature flag is disabled.
          # This is done in order to keep the old behavior of sending emails for
          # any project which does not have the new `incident_management` feature.
          # See point 3 in
          # https://gitlab.com/gitlab-org/gitlab/merge_requests/9830#what-does-this-mr-do
          return firings.any? unless incident_management_available?

          incident_management_setting.send_email && firings.any?
        end

        def process_issues?
          return unless incident_management_available?

          incident_management_setting.create_issue?
        end

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
          valid_for_manual?(token) || valid_for_managed?(token)
        end

        def valid_for_manual?(token)
          prometheus = project.find_or_initialize_service('prometheus')
          return false unless prometheus.manual_configuration?

          if setting = project.alerting_setting
            compare_token(token, setting.token)
          else
            token.nil?
          end
        end

        def valid_for_managed?(token)
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

          alert = find_alert(project, alert_id)
          return unless alert

          cluster = alert.environment.deployment_platform&.cluster
          return unless cluster&.enabled?
          return unless cluster.application_prometheus_available?

          cluster.application_prometheus
        end

        def find_alert(project, metric)
          Projects::Prometheus::AlertsFinder
            .new(project: project, metric: metric)
            .execute
            .first
        end

        def gitlab_alert_id
          alerts&.first&.dig('labels', 'gitlab_alert_id')
        end

        def compare_token(expected, actual)
          return unless expected && actual

          ActiveSupport::SecurityUtils.secure_compare(expected, actual)
        end

        def send_alert_email
          notification_service
            .async
            .prometheus_alerts_fired(project, firings)
        end

        def process_incident_issues
          alerts.each do |alert|
            IncidentManagement::ProcessPrometheusAlertWorker
              .perform_async(project.id, alert.to_h)
          end
        end

        def persist_events
          CreateEventsService.new(project, nil, params).execute
        end
      end
    end
  end
end
