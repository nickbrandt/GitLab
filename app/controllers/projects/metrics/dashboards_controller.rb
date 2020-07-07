# frozen_string_literal: true

module Projects
  module Metrics
    class DashboardController < Projects::ApplicationController
      include MetricsDashboard
      include ::Metrics::Dashboard::PrometheusApiProxy

      before_action only: [:metrics, :metrics_dashboard] do
        authorize_metrics_dashboard!

        push_frontend_feature_flag(:prometheus_computed_alerts)
      end

      def index
        respond_to do |format|
          format.html
          format.json do
            # Currently, this acts as a hint to load the metrics details into the cache
            # if they aren't there already
            @metrics = environment.metrics || {}

            render json: @metrics, status: @metrics.any? ? :ok : :no_content
          end
        end
      end

      private

      def proxyable
        @proxyable ||= if environment
                         environment.prometheus_adapter
                       else
                         ::Clusters::ClustersHierarchy.new(project)
                           .base_and_ancestors
                           .default_environment
                           .first
                           .prometheus_adapter
                       end
      end

      def environment
        if params[:env_id]
          @environment ||= project.environments.find(params[:env_id])
        end
      end

      def proxy_variable_substitution_service
        ::Prometheus::ProxyVariableSubstitutionService
      end
    end
  end
end
