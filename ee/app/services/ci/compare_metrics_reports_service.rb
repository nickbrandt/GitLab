# frozen_string_literal: true

module Ci
  class CompareMetricsReportsService < ::Ci::CompareReportsBaseService
    def comparer_class
      Gitlab::Ci::Reports::Metrics::ReportsComparer
    end

    def serializer_class
      MetricsReportsComparerSerializer
    end

    def get_report(pipeline)
      pipeline&.metrics_report
    end
  end
end
