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
  end
end
