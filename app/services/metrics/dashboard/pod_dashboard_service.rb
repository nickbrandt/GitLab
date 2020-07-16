# frozen_string_literal: true

module Metrics
  module Dashboard
    class PodDashboardService < ::Metrics::Dashboard::PredefinedDashboardService
      DASHBOARD_PATH = 'config/prometheus/pod_metrics.yml'
      DASHBOARD_NAME = 'Pod Health'

      # Update this value when the dashboard content is updated. This will force
      # the cache to be regenerated.
      DASHBOARD_VERSION = 1

      private

      def dashboard_version
        DASHBOARD_VERSION
      end
    end
  end
end
