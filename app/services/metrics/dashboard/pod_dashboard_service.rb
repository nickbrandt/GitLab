# frozen_string_literal: true

module Metrics
  module Dashboard
    class PodDashboardService < ::Metrics::Dashboard::PredefinedDashboardService
      DASHBOARD_PATH = 'config/prometheus/pod_metrics.yml'
      DASHBOARD_NAME = N_('Pod Health')

      class << self
        def all_dashboard_paths(_project)
          [{
            path: DASHBOARD_PATH,
            display_name: _(DASHBOARD_NAME),
            default: false,
            system_dashboard: false
          }]
        end
      end
    end
  end
end
