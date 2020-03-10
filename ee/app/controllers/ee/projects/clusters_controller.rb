# frozen_string_literal: true

module EE
  module Projects
    module ClustersController
      def metrics_dashboard_params
        params.permit(:embedded, :group, :title, :y_label).merge(
          {
            cluster: cluster,
            cluster_type: :project
          }
        )
      end
    end
  end
end
