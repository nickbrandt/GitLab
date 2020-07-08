# frozen_string_literal: true

module EE
  module ClusterablePresenter
    def metrics_cluster_path(cluster, params = {})
      raise NotImplementedError
    end

    def metrics_dashboard_path(cluster)
      raise NotImplementedError
    end
  end
end
