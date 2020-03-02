# frozen_string_literal: true

module EE
  module Projects
    module Prometheus
      module AlertPresenter
        extend ::Gitlab::Utils::Override

        METRIC_TIME_WINDOW = 30.minutes

        override :metric_embed_for_alert
        def metric_embed_for_alert
          return unless gitlab_alert

          time = starts_at ? Time.rfc3339(starts_at) : Time.current
          url = metrics_dashboard_project_prometheus_alert_url(
            project,
            gitlab_alert.prometheus_metric_id,
            environment_id: environment.id,
            start: format_embed_timestamp(time - METRIC_TIME_WINDOW),
            end: format_embed_timestamp(time + METRIC_TIME_WINDOW)
          )

          "\n[](#{url})"
        end

        def format_embed_timestamp(timestamp)
          timestamp.utc.strftime('%FT%TZ')
        end
      end
    end
  end
end
