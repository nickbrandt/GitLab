# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class IssueRecordsFetcher
      include StageQueryHelpers
      include Gitlab::CycleAnalytics::MetricsTables

      attr_reader :stage

      def initialize(stage, query)
        @stage = stage
        @query = query
      end

      def records
        q = @query.project(*projections, round_duration_to_seconds.as('total_time'))
        execute_query(q).to_a
      end

      def serialized_records
        records.map { |r| AnalyticsIssueSerializer.new.represent(r) }
      end

      def projections
        [
          issue_table[:title],
          issue_table[:iid],
          issue_table[:id],
          issue_table[:created_at],
          issue_table[:author_id],
          projects_table[:name],
          routes_table[:path]
        ]
      end
    end
  end
end
