# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class DataCollector
      def initialize(stage, params = {})
        @stage = stage
        @params = params
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

      attr_reader :stage, :params

      def query
        DataFilter.new(stage: stage, params: params).apply
      end
    end
  end
end
