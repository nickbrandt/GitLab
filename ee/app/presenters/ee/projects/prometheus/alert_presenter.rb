# frozen_string_literal: true

module EE
  module Projects
    module Prometheus
      module AlertPresenter
        extend ::Gitlab::Utils::Override

        METRIC_TIME_WINDOW = 30.minutes

        override :metric_embed_for_alert
        def metric_embed_for_alert
          url = embed_url_for_gitlab_alert || embed_url_for_self_managed_alert

          "\n[](#{url})" if url
        end

        private

        def embed_url_for_gitlab_alert
          return unless gitlab_alert

          metrics_dashboard_project_prometheus_alert_url(
            project,
            gitlab_alert.prometheus_metric_id,
            environment_id: environment.id,
            **alert_embed_window_params(embed_time)
          )
        end

        def embed_url_for_self_managed_alert
          return unless environment && full_query && title

          metrics_dashboard_project_environment_url(
            project,
            environment,
            embed_json: dashboard_for_self_managed_alert.to_json,
            **alert_embed_window_params(embed_time)
          )
        end

        def embed_time
          starts_at ? Time.rfc3339(starts_at) : Time.current
        end

        def alert_embed_window_params(time)
          {
            start: format_embed_timestamp(time - METRIC_TIME_WINDOW),
            end: format_embed_timestamp(time + METRIC_TIME_WINDOW)
          }
        end

        def format_embed_timestamp(time)
          time.utc.strftime('%FT%TZ')
        end

        def dashboard_for_self_managed_alert
          {
            panel_groups: [{
              panels: [{
                type: 'line-graph',
                title: title,
                y_label: y_label,
                metrics: [{
                  query_range: full_query
                }]
              }]
            }]
          }
        end
      end
    end
  end
end
