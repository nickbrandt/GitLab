# frozen_string_literal: true

require 'set'

module EE
  module Gitlab
    module MetricsDashboard
      module Stages
        class AlertsInserter < ::Gitlab::MetricsDashboard::Stages::BaseStage
          def transform!(dashboard)
            return if metrics_with_alerts.empty?

            for_metrics(dashboard) do |metric|
              next unless metrics_with_alerts.include?(metric[:metric_id])

              metric[:alert_path] = alert_path(metric[:metric_id], project, environment)
            end
          end

          private

          def metrics_with_alerts
            return @metrics_with_alerts if @metrics_with_alerts

            alerts = ::Projects::Prometheus::AlertsFinder
                       .new(project: project, environment: environment)
                       .execute
                       .pluck(:prometheus_metric_id)

            @metrics_with_alerts = Set.new(alerts)
          end

          def alert_path(metric_id, project, environment)
            ::Gitlab::Routing.url_helpers.project_prometheus_alert_path(project, metric_id, environment_id: environment.id, format: :json)
          end
        end
      end
    end
  end
end
