# frozen_string_literal: true

require 'set'

module EE
  module Gitlab
    module MetricsDashboard
      module Stages
        class AlertsInserter < ::Gitlab::MetricsDashboard::Stages::BaseStage
          def transform!
            alerts = metrics_with_alerts

            for_metrics do |metric|
              next unless metric_id = metric[:metric_id]
              next unless alerts.include?(metric_id)

              metric[:alert_path] = alert_path(metric_id, project, environment)
            end
          end

          private

          def metrics_with_alerts
            alerts = ::Projects::Prometheus::AlertsFinder
                       .new(project: project, environment: environment)
                       .execute

            Set.new(alerts.map(&:id))
          end

          def alert_path(metric_id, project, environment)
            ::Gitlab::Routing.url_helpers.project_prometheus_alert_path(project, metric_id, environment_id: environment.id, format: :json)
          end
        end
      end
    end
  end
end
