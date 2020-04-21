# frozen_string_literal: true

module EE
  module Clusters
    module ClusterPresenter
      def health_data(clusterable)
        {
          'clusters-path': clusterable.index_path,
          'metrics-endpoint': clusterable.metrics_cluster_path(cluster, format: :json),
          'dashboard-endpoint': clusterable.metrics_dashboard_path(cluster),
          'documentation-path': help_page_path('user/project/clusters/index', anchor: 'monitoring-your-kubernetes-cluster-ultimate'),
          'empty-getting-started-svg-path': image_path('illustrations/monitoring/getting_started.svg'),
          'empty-loading-svg-path': image_path('illustrations/monitoring/loading.svg'),
          'empty-no-data-svg-path': image_path('illustrations/monitoring/no_data.svg'),
          'empty-unable-to-connect-svg-path': image_path('illustrations/monitoring/unable_to_connect.svg'),
          'settings-path': '',
          'project-path': '',
          'tags-path': '',
          'alerts-endpoint': alerts_endpoint,
          'prometheus-alerts-available': prometheus_alerts_available
        }
      end

      private

      def image_path(path)
        ActionController::Base.helpers.image_path(path)
      end

      def alerts_endpoint
        '/' if ::Feature.enabled?(:prometheus_computed_alerts)
      end

      def prometheus_alerts_available
        'true' if ::Feature.enabled?(:prometheus_computed_alerts)
      end
    end
  end
end
