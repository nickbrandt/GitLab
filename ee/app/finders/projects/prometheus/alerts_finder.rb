# frozen_string_literal: true

module Projects
  module Prometheus
    # Find Prometheus alerts by +project+, by +environment+, or both.
    #
    # Optionally filter by +metric+.
    #
    # Arguments:
    #   params:
    #     project: Project | integer
    #     environment: Environment | integer
    #     metric: PrometheusMetric | integer
    class AlertsFinder
      def initialize(params = {})
        unless params[:project] || params[:environment]
          raise ArgumentError,
            'Please provide either :project or :environment, or both'
        end

        @params = params
      end

      # Find all matching alerts
      #
      # @return [ActiveRecord::Relation<PrometheusAlert>]
      def execute
        relation = by_project(PrometheusAlert)
        relation = by_environment(relation)
        relation = by_metric(relation)
        relation = ordered(relation)

        relation
      end

      private

      attr_reader :params

      def by_project(relation)
        return relation unless params[:project]

        relation.for_project(params[:project])
      end

      def by_environment(relation)
        return relation unless params[:environment]

        relation.for_environment(params[:environment])
      end

      def by_metric(relation)
        return relation unless params[:metric]

        relation.for_metric(params[:metric])
      end

      def ordered(relation)
        relation.order_by('id_asc')
      end
    end
  end
end
