# frozen_string_literal: true
#
module Metrics
  module Dashboard
    class ClusterMetricsEmbedService < Metrics::Dashboard::DynamicEmbedService
      class << self
        def valid_params?(params)
          [
            params[:cluster],
            params[:embedded] == 'true',
            params[:group].present?,
            params[:title].present?,
            params[:y_label].present?
          ].all?
        end
      end

      private

      # Permissions are handled at the controller level
      def allowed?
        true
      end

      def dashboard_path
        ::Metrics::Dashboard::ClusterDashboardService::DASHBOARD_PATH
      end

      def sequence
        [
          STAGES::ClusterEndpointInserter
        ]
      end
    end
  end
end
