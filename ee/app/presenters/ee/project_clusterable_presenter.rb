# frozen_string_literal: true

module EE
  module ProjectClusterablePresenter
    extend ::Gitlab::Utils::Override

    override :metrics_cluster_path
    def metrics_cluster_path(cluster, params = {})
      metrics_project_cluster_path(clusterable, cluster, params)
    end

    override :metrics_dashboard_path
    def metrics_dashboard_path(cluster)
      metrics_dashboard_project_cluster_path(clusterable, cluster)
    end
  end
end
