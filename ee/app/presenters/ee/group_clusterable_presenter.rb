# frozen_string_literal: true

module EE
  module GroupClusterablePresenter
    extend ::Gitlab::Utils::Override

    override :metrics_cluster_path
    def metrics_cluster_path(cluster, params = {})
      metrics_group_cluster_path(clusterable, cluster, params)
    end
  end
end
