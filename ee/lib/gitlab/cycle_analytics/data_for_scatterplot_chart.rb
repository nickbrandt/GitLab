# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    class DataForScatterplotChart
      include StageQueryHelpers

      def initialize(stage:, query:)
        @stage = stage
        @query = query
      end

      def load
        q = query.project(stage.model_to_query.arel_table[:id].as('id'))
        q = q.project(round_duration_to_seconds.as('duration_in_seconds'))
        q = q.project(Arel::Nodes::Extract.new(stage.end_event.timestamp_projection, :epoch).as('finished_at'))
        execute_query(q).to_a
      end

      private

      attr_reader :stage, :query
    end
  end
end
