# frozen_string_literal: true

# Manages url matching for metrics dashboards.
module EE
  module Gitlab
    module Metrics
      module Dashboard
        module Url
          # Matches dashboard urls for a metric chart embed
          # for a specifc firing GitLab alert
          #
          # EX - https://<host>/<namespace>/<project>/prometheus/alerts/<alert_id>/metrics_dashboard
          def alert_regex
            strong_memoize(:alert_regex) do
              regex_for_project_metrics(
                %r{
                  /prometheus
                  /alerts
                  /(?<alert>\d+)
                  /metrics_dashboard
                }x
              )
            end
          end
        end
      end
    end
  end
end
