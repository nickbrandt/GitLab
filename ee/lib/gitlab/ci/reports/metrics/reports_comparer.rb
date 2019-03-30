# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Metrics
        class ReportsComparer
          include Gitlab::Utils::StrongMemoize

          attr_reader :base_report, :head_report

          def initialize(base_report, head_report)
            @base_report = base_report || ::Gitlab::Ci::Reports::Metrics::Report.new
            @head_report = head_report
          end

          def new_metrics
            strong_memoize(:new_metrics) do
              names = @head_report.found_metrics.keys - @base_report.found_metrics.keys
              @head_report.metrics.select { |metric| names.include?(metric.name) }
            end
          end

          def existing_metrics
            strong_memoize(:existing_metrics) do
              names = @base_report.found_metrics.keys & @head_report.found_metrics.keys
              @head_report.metrics.select { |metric| names.include?(metric.name) }
            end
          end

          def removed_metrics
            strong_memoize(:removed_metrics) do
              names = @base_report.found_metrics.keys - @head_report.found_metrics.keys
              @base_report.metrics.select { |metric| names.include?(metric.name) }
            end
          end
        end
      end
    end
  end
end
