# frozen_string_literal: true

module EE
  module Projects
    module ClustersController
      def metrics_dashboard_params
        {
          cluster: cluster,
          cluster_type: :project
        }
      end
    end
  end
end
