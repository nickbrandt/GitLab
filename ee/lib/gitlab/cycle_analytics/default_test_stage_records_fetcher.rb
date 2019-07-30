# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class DefaultTestStageRecordsFetcher
      include StageQueryHelpers
      include Gitlab::CycleAnalytics::MetricsTables

      attr_reader :stage

      def initialize(stage, query)
        @stage = stage
        @query = query
      end

      def records
        q = @query
          .join(build_table).on(mr_metrics_table[:pipeline_id].eq(build_table[:commit_id]))
          .project(*projections, round_duration_to_seconds.as('duration_in_seconds'))
        result = execute_query(q).to_a
        Updater.update!(result, from: 'id', to: 'build', klass: ::Ci::Build)
        result
      end

      def serialize
        AnalyticsBuildSerializer.new.represent(records.map { |e| e['build'] })
      end

      def projections
        [
          build_table[:id]
        ]
      end
    end
  end
end

