# frozen_string_literal: true

module EE
  module ClusterablePresenter
    extend ::Gitlab::Utils::Override

    def metrics_cluster_path(cluster, params = {})
      raise NotImplementedError
    end

    def metrics_dashboard_path(cluster)
      raise NotImplementedError
    end

    private

    override :multiple_clusters_available?
    def multiple_clusters_available?
      clusterable.feature_available?(:multiple_clusters)
    end
  end
end
