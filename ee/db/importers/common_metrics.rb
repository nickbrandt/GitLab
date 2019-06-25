require_relative './common_metrics/prometheus_metric_enums'

module EE
  module Importers
    module CommonMetrics
      # rubocop: disable Cop/InjectEnterpriseEditionModule
      def self.prepended(base)
        ::Importers::CommonMetrics::PrometheusMetricEnums.prepend EE::Importers::CommonMetrics::PrometheusMetricEnums
      end
    end
  end
end
