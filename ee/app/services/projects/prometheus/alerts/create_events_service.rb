# frozen_string_literal: true

module Projects
  module Prometheus
    module Alerts
      # Persists a series of Prometheus alert events as list of PrometheusAlertEvent.
      class CreateEventsService < BaseService
        def execute
          create_events_from(alerts)
        end

        private

        def create_events_from(alerts)
          Array.wrap(alerts).map { |alert| create_event(alert) }.compact
        end

        def create_event(payload)
          parsed_alert = Gitlab::Alerting::Alert.new(project: project, payload: payload)

          return unless parsed_alert.valid?

          event = if parsed_alert.gitlab_managed?
                    build_managed_prometheus_alert_event(parsed_alert)
                  else
                    build_self_managed_prometheus_alert_event(parsed_alert)
                  end

          if event
            result = case parsed_alert.status
                     when 'firing'
                       event.fire(parsed_alert.starts_at)
                     when 'resolved'
                       event.resolve(parsed_alert.ends_at)
                     end
          end

          event if result
        end

        def alerts
          params['alerts']
        end

        def find_alert(metric)
          Projects::Prometheus::AlertsFinder
            .new(project: project, metric: metric)
            .execute
            .first
        end

        def build_managed_prometheus_alert_event(parsed_alert)
          alert = find_alert(parsed_alert.metric_id)

          return if alert.blank?

          payload_key = PrometheusAlertEvent.payload_key_for(parsed_alert.metric_id, parsed_alert.starts_at_raw)

          PrometheusAlertEvent.find_or_initialize_by_payload_key(parsed_alert.project, alert, payload_key)
        end

        def build_self_managed_prometheus_alert_event(parsed_alert)
          payload_key = SelfManagedPrometheusAlertEvent.payload_key_for(parsed_alert.starts_at_raw, parsed_alert.title, parsed_alert.full_query)

          SelfManagedPrometheusAlertEvent.find_or_initialize_by_payload_key(parsed_alert.project, payload_key) do |event|
            event.environment      = parsed_alert.environment
            event.title            = parsed_alert.title
            event.query_expression = parsed_alert.full_query
          end
        end
      end
    end
  end
end
