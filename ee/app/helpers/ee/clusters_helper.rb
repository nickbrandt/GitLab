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
  end
end
