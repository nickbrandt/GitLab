# frozen_string_literal: true

# Manages url matching for metrics dashboards.
module EE
  module Gitlab
    module Metrics
      module Dashboard
        module Url
          # Matches dashboard urls for a metric chart embed
          # for cluster metrics
          #
          # EX - https://<host>/<namespace>/<project>/-/clusters/<cluster_id>/?group=Cluster%20Health&title=Memory%20Usage&y_label=Memory%20(GiB)
          def clusters_regex
            strong_memoize(:clusters_regex) do
              regex_for_project_metrics(
                %r{
                  /clusters
                  /(?<cluster_id>\d+)
                  [/]?
                }x
              )
            end
          end
        end
      end
    end
  end
end
