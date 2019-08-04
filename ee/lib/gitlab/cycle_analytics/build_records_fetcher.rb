# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class BuildRecordsFetcher
      include StageQueryHelpers
      include Gitlab::CycleAnalytics::MetricsTables

      def initialize(stage, query)
        @stage = stage
        @query = query
      end

      def serialized_records
        AnalyticsBuildSerializer.new.represent(records.map { |e| e['build'] })
      end

      attr_reader :stage, :query

      def records
        q = query
          .join(build_table).on(mr_metrics_table[:pipeline_id].eq(build_table[:commit_id]))
          .project(*projections, round_duration_to_seconds.as('total_time'))
        result = execute_query(q).to_a
        Updater.update!(result, from: 'id', to: 'build', klass: ::Ci::Build)

        result
      end

      def projections
        [
          build_table[:id]
        ]
      end
    end
  end
end
