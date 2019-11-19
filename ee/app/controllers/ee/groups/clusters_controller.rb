# frozen_string_literal: true

module EE
  module Groups
    module ClustersController
      extend ActiveSupport::Concern

      def metrics_dashboard_params
        {
          cluster: cluster,
          cluster_type: :group,
          group: group
        }
      end
    end
  end
end
