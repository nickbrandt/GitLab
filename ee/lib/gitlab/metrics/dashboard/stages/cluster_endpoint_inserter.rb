# frozen_string_literal: true

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class ClusterEndpointInserter < BaseStage
          def transform!
            verify_params

            for_metrics do |metric|
              metric[:prometheus_endpoint_path] = endpoint_for_metric(metric)
            end
          end

          private

          def endpoint_for_metric(metric)
            proxy_path = query_type(metric)
            query = query_for_metric(metric)

            case params[:cluster_type]
            when :admin
              Gitlab::Routing.url_helpers.prometheus_api_admin_cluster_path(
                params[:cluster],
                proxy_path: proxy_path,
                query: query
              )
            when :group
              Gitlab::Routing.url_helpers.prometheus_api_group_cluster_path(
                params[:group],
                params[:cluster],
                proxy_path: proxy_path,
                query: query
              )
            when :project
              Gitlab::Routing.url_helpers.prometheus_api_project_cluster_path(
                project,
                params[:cluster],
                proxy_path: proxy_path,
                query: query
              )
            else
              Errors::DashboardProcessingError.new('Unrecognized cluster type')
            end
          end

          def query_type(metric)
            metric[:query] ? :query : :query_range
          end

          def query_for_metric(metric)
            query = metric[query_type(metric)]

            raise Errors::MissingQueryError.new('Each "metric" must define one of :query or :query_range') unless query

            query
          end

          def verify_params
            raise Errors::DashboardProcessingError.new('Cluster is required for Stages::ClusterEndpointInserter') unless params[:cluster]
            raise Errors::DashboardProcessingError.new('Cluster type must be specificed for Stages::ClusterEndpointInserter') unless params[:cluster_type]

            verify_type_params
          end

          def verify_type_params
            case params[:cluster_type]
            when :group
              raise Errors::DashboardProcessingError.new('Group is required when cluster_type is :group') unless params[:group]
            when :project
              raise Errors::DashboardProcessingError.new('Project is required when cluster_type is :project') unless project
            end
          end
        end
      end
    end
  end
end
