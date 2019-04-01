# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Metrics
        class ReportsComparer
          include Gitlab::Utils::StrongMemoize

          attr_reader :base_report, :head_report

          ComparedMetric = Struct.new(:name, :value, :previous_value)

          def initialize(base_report, head_report)
            @base_report = base_report || ::Gitlab::Ci::Reports::Metrics::Report.new
            @head_report = head_report
          end

          def new_metrics
            strong_memoize(:new_metrics) do
              head_report.metrics.map do |key, value|
                ComparedMetric.new(key, value) unless base_report.metrics.include?(key)
              end.compact
            end
          end

          def existing_metrics
            strong_memoize(:existing_metrics) do
              base_report.metrics.map do |key, value|
                new_value = head_report.metrics[key]
                ComparedMetric.new(key, new_value, value) if new_value
              end.compact
            end
          end

          def removed_metrics
            strong_memoize(:removed_metrics) do
              base_report.metrics.map do |key, value|
                ComparedMetric.new(key, value) unless head_report.metrics.include?(key)
              end.compact
            end
          end
        end
      end
    end
  end
end
