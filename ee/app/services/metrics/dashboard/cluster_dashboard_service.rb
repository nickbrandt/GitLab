# frozen_string_literal: true

# Fetches the system metrics dashboard and formats the output.
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class ClusterDashboardService < ::Metrics::Dashboard::PredefinedDashboardService
      DASHBOARD_PATH = 'ee/config/prometheus/cluster_metrics.yml'
      DASHBOARD_NAME = 'Cluster'

      SEQUENCE = [
        STAGES::CommonMetricsInserter,
        STAGES::ClusterEndpointInserter,
        STAGES::Sorter
      ].freeze

      class << self
        def valid_params?(params)
          params[:cluster].present?
        end
      end

      # Permissions are handled at the controller level
      def allowed?
        true
      end
    end
  end
end
