# frozen_string_literal: true

module EE
  module ClustersHelper
    extend ::Gitlab::Utils::Override

    override :has_multiple_clusters?
    def has_multiple_clusters?
      clusterable.feature_available?(:multiple_clusters)
    end

    def show_cluster_health_graphs?
      clusterable.feature_available?(:cluster_health)
    end

    def cluster_health_data(cluster)
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
        'tags-path': ''
      }
    end
  end
end
