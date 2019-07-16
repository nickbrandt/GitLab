# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class IssueRecordsFetcher
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
          Issue.arel_table[:title],
          Issue.arel_table[:iid],
          Issue.arel_table[:id],
          Issue.arel_table[:created_at],
          Issue.arel_table[:author_id]
        ]
      end
    end
  end
end
