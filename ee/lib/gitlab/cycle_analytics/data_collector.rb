# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class DataCollector
      include StageQueryHelpers

      def initialize(stage, from = nil, to = Time.now)
        @stage = stage
        @from = from
        @to = to
      end

      def records
        RecordsFetcher.build(stage, query)
      end


      def with_end_date_and_duration_in_seconds
        q = query.project(stage.model_to_query.arel_table[:id].as('id'))
        q = q.project(round_duration_to_seconds.as('duration_in_seconds'))
        q = q.project(stage.end_event.timestamp_projection.as('finished_at'))

        execute_query(q).to_a
      end

      def median
        Median.new(stage, query)
      end

      private

      attr_reader :stage, :from, :to

      def query
        q = DataFilter.new(stage: stage).apply(stage.model_to_query.arel_table)
        q = stage.start_event.apply_query_customization(q)
        q = stage.end_event.apply_query_customization(q)
        q.where(duration.gt(zero_interval))
      end
    end
  end
end
