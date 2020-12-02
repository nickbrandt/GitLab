# frozen_string_literal: true

module Gitlab
  class UsageDataCollector < UsageData
    @metrics = []

    class << self
      attr_reader :metrics

      def add_metric(full_path, value)
        @metrics << Gitlab::UsageData::Metric.new(full_path, value)
      end

      def count(relation, column = nil, batch: true, batch_size: nil, start: nil, finish: nil, full_path: '')
        add_metric(full_path, super(relation, column, batch: batch, batch_size: batch_size, start: start, finish: finish, full_path: full_path))
      end

      def alt_usage_data(value = nil, fallback: FALLBACK, full_path: '', &block)
        add_metric(full_path, super(value, fallback: fallback, full_path: full_path, &block))
      end

      def uncached_data
        clear_memoized

        # Add metrics
        license_usage_data

        metrics.map(&:to_h).reduce({}, :merge)
      end
    end
  end
end
