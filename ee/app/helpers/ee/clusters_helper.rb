# frozen_string_literal: true

module EE
  module ClustersHelper
    extend ::Gitlab::Utils::Override

    override :has_multiple_clusters?
    def has_multiple_clusters?
      clusterable.feature_available?(:multiple_clusters)
    end

    override :show_cluster_health_graphs?
    def show_cluster_health_graphs?(cluster)
      cluster.project_type? && cluster.project.feature_available?(:cluster_health)
    end

    def cluster_health_data(cluster)
      project = cluster.project

      {
        'metrics-endpoint': metrics_project_cluster_path(project, cluster, format: :json),
        'clusters-path': project_clusters_path(project),
        'documentation-path': help_page_path('administration/monitoring/prometheus/index.md'),
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
