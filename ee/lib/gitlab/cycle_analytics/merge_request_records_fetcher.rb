# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class MergeRequestRecordsFetcher
      include StageQueryHelpers

      attr_reader :stage

      def initialize(stage, query)
        @stage = stage
        @query = query
      end

      def records
        q = @query.project(*projections, round_duration_to_seconds.as('duration_in_seconds'))
        execute_query(q).to_a
      end

      def projections
        [
          MergeRequest.arel_table[:title],
          MergeRequest.arel_table[:iid],
          MergeRequest.arel_table[:id],
          MergeRequest.arel_table[:created_at],
          MergeRequest.arel_table[:state],
          MergeRequest.arel_table[:author_id]
        ]
      end
    end
  end
end
