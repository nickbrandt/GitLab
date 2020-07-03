# frozen_string_literal: true

# Copies system dashboard definition in .yml file into designated
# .yml file inside `.gitlab/dashboards`
module EE
  module Metrics
    module Dashboard
      module CloneDashboardService
        extend ActiveSupport::Concern

        class_methods do
          extend ::Gitlab::Utils::Override

          override :sequences
          def sequences
            super.merge(::Metrics::Dashboard::ClusterDashboardService::DASHBOARD_PATH => [::Gitlab::Metrics::Dashboard::Stages::CommonMetricsInserter,
                                                                                          ::Gitlab::Metrics::Dashboard::Stages::Sorter].freeze)
          end
        end
      end
    end
  end
end
