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

          override :allowed_dashboard_templates
          def allowed_dashboard_templates
            @allowed_dashboard_templates ||= (Set[::Metrics::Dashboard::ClusterDashboardService::DASHBOARD_PATH] + super).freeze
          end

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
