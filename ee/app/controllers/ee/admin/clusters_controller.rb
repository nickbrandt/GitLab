# frozen_string_literal: true

module EE
  module Admin
    module ClustersController
      def metrics_dashboard_params
        {
          cluster: cluster,
          cluster_type: :admin
        }
      end
    end
  end
end
