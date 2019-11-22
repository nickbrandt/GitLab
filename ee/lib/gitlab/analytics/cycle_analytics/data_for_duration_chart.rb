# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class DataForDurationChart
        include StageQueryHelpers

        MAX_RESULTS = 500

        def initialize(stage:, query:)
          @stage = stage
          @query = query
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def load
          query
            .select(round_duration_to_seconds.as('duration_in_seconds'), stage.end_event.timestamp_projection.as('finished_at'))
            .reorder(stage.end_event.timestamp_projection.desc)
            .limit(MAX_RESULTS)
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        attr_reader :stage, :query
      end
    end
  end
end
