# frozen_string_literal: true

# Fetches the system metrics dashboard and formats the output.
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class ClusterDashboardService < ::Metrics::Dashboard::BaseService
      CLUSTER_DASHBOARD_PATH = 'ee/config/prometheus/cluster_metrics_new.yml'
      CLUSTER_DASHBOARD_NAME = 'Cluster'

      SEQUENCE = [
        STAGES::CommonMetricsInserter,
        STAGES::ClusterEndpointInserter,
        STAGES::Sorter
      ].freeze

      private

      def cache_key
        "metrics_dashboard_#{dashboard_path}"
      end

      def dashboard_path
        CLUSTER_DASHBOARD_PATH
      end

      # Returns the base metrics shipped with every GitLab service.
      def get_raw_dashboard
        yml = File.read(Rails.root.join(dashboard_path))

        YAML.safe_load(yml)
      end

      def sequence
        SEQUENCE
      end
    end
  end
end
