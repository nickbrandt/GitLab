# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class DataCollector
      def initialize(stage, from = nil, to = Time.now)
        @stage = stage
        @from = from
        @to = to
      end

      def records_fetcher
        RecordsFetcher.new(stage: stage, query: query)
      end

      def with_end_date_and_duration_in_seconds
        DataForScatterplotChart.new(stage: stage, query: query).load
      end

      def median
        Median.new(stage, query)
      end

      private

      attr_reader :stage, :from, :to

      def query
        DataFilter.new(stage: stage).apply
      end
    end
  end
end
