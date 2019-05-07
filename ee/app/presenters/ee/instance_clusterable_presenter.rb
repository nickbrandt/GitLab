# frozen_string_literal: true

module EE
  module InstanceClusterablePresenter
    extend ::Gitlab::Utils::Override

    override :metrics_cluster_path
    def metrics_cluster_path(cluster, params = {})
      metrics_admin_cluster_path(cluster, params)
    end
  end
end
