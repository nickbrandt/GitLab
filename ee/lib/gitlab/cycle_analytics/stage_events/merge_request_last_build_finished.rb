# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      class MergeRequestLastBuildFinished < SimpleStageEvent
        def self.identifier
          :merge_request_last_build_finished
        end

        def object_type
          MergeRequest
        end

        def timestamp_projection
          mr_metrics_table[:latest_build_finished_at]
        end

        def apply_query_customization(query)
          inner_join(query, mr_metrics_table[:merge_request_id])
        end
      end
    end
  end
end
