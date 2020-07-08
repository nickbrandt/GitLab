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

      before_action :environment

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
        @proxyable ||=
          if environment
            environment.prometheus_adapter
          elsif project.prometheus_service&.can_query?
            project.prometheus_service
          else
            ::Clusters::ClustersHierarchy.new(project)
              .base_and_ancestors
              .default_environment
              .first
              .prometheus_adapter
          end
      end

      def environment
        @environment ||= project.environments.find(params[:env_id]) if params[:env_id]

        @environment
      end

      def proxy_variable_substitution_service
        ::Prometheus::ProxyVariableSubstitutionService
      end

      def metrics_dashboard_params
        params
          .permit(:embedded, :group, :title, :y_label, :dashboard_path, :environment, :sample_metrics, :embed_json)
          .merge(dashboard_path: params[:dashboard], environment: environment)
      end

      def include_all_dashboards?
        !params[:embedded]
      end
    end
  end
end
