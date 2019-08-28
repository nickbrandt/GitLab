# frozen_string_literal: true

# Fetches the system metrics dashboard and formats the output.
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class ClusterDashboardService < ::Metrics::Dashboard::BaseService
      CLUSTER_DASHBOARD_PATH = 'ee/config/prometheus/cluster_metrics_new.yml'
      CLUSTER_DASHBOARD_NAME = 'Cluster'

      class << self
        def all_dashboard_paths(_project)
          [{
            path: CLUSTER_DASHBOARD_PATH,
            display_name: CLUSTER_DASHBOARD_NAME,
            default: true
          }]
        end
      end

      private

      def dashboard_path
        CLUSTER_DASHBOARD_PATH
      end

      # Returns the base metrics shipped with every GitLab service.
      def get_raw_dashboard
        yml = File.read(Rails.root.join(dashboard_path))

        YAML.safe_load(yml)
      end

      def cache_key
        "metrics_dashboard_#{dashboard_path}"
      end

      def insert_project_metrics?
        false
      end
    end
  end
end
