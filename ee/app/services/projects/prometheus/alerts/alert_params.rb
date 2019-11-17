# frozen_string_literal: true

module Projects
  module Prometheus
    module Alerts
      module AlertParams
        def alert_params
          valid_operator && valid_alert_query
          params
        end

        private

        def valid_operator
          return params if params[:operator].blank?

          params.merge!(
            operator: PrometheusAlert.operator_to_enum(params[:operator])
          )
        end

        def valid_alert_query
          return if params[:alert_query].blank?

          embedded_metric_ids = ordered_replacement_metrics.flatten.map do |metric|
            if params[:alert_query].gsub!(/\(\s*#{Regexp.escape(metric.legend)}\s*\)/, "(!#{metric.id})")
              metric.id
            else
              nil
            end
          end.compact
          ensure_matching_metric_id(embedded_metric_ids)
        end

        def ordered_replacement_metrics
          # if a metric was specified in the params, attempt the replacement
          # below on that one first - if a user is specifying ambiguous legends
          # they expect the one to be used from the metric where they set the
          # alert
          specified_metric = nil
          if params[:prometheus_metric_id].present?
            specified_metric = PrometheusMetric.for_project(project_for_dashboard)
                                 .find(params[:prometheus_metric_id])
          end

          metrics = PrometheusMetric.for_project(project_for_dashboard).order_by_legend_length
          [specified_metric, metrics].flatten.compact
        end

        def ensure_matching_metric_id(embedded_metric_ids)
          if embedded_metric_ids.any?
            if params[:prometheus_metric_id].blank? ||
               !embedded_metric_ids.include?(params[:prometheus_metric_id].to_i)
              params[:prometheus_metric_id] = embedded_metric_ids.first
            end
          end
        end

        def project_for_dashboard
          environment&.project
        end

        def metrics_dashboard_params
          params
            .permit(:embedded, :group, :title, :y_label)
            .to_h.symbolize_keys
            .merge(dashboard_path: params[:dashboard], environment: environment)
        end

        def environment
          Environment.find(params[:environment_id])
        end

        def dashboard_finder
          ::Gitlab::Metrics::Dashboard::Finder
        end
      end
    end
  end
end
