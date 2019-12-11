# frozen_string_literal: true

module EE
  module Projects
    module PerformanceMonitoring
      module DashboardsController
        extend ::Gitlab::Utils::Override

        DASHBOARD_TEMPLATES = {
          ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH => true,
          ::Metrics::Dashboard::ClusterDashboardService::DASHBOARD_PATH => true
        }.freeze

        private

        override :dashboard_templates
        def dashboard_templates
          DASHBOARD_TEMPLATES
        end
      end
    end
  end
end
