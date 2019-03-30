# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Metrics
        class Report
          attr_reader :found_metrics

          def initialize
            @found_metrics = {}
          end

          def metrics
            @found_metrics.values
          end

          def add_metric(key, value)
            @found_metrics[key] = ::Gitlab::Ci::Reports::Metrics::Metric.new(key, value)
          end
        end
      end
    end
  end
end
