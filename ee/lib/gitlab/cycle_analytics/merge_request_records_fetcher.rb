# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class MergeRequestRecordsFetcher
      include StageQueryHelpers
      include Gitlab::CycleAnalytics::MetricsTables

      attr_reader :stage

      def initialize(stage, query)
        @stage = stage
        @query = query
      end

      def records
        q = @query.project(*projections, round_duration_to_seconds.as('duration_in_seconds'))
        execute_query(q).to_a
      end

      def serialized_records
        records.map { |r| AnalyticsIssueSerializer.new.represent(r) }
      end

      def projections
        [
          mr_table[:title],
          mr_table[:iid],
          mr_table[:id],
          mr_table[:created_at],
          mr_table[:state],
          mr_table[:author_id],
          projects_table[:name],
          routes_table[:path]
        ]
      end
    end
  end
end
