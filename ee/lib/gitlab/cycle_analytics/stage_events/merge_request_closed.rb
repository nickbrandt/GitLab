# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      class MergeRequestClosed < SimpleStageEvent
        def self.name
          s_("CycleAnalyticsEvent|Merge request closed")
        end

        def self.identifier
          :merge_request_closed
        end

        def object_type
          MergeRequest
        end

        def timestamp_projection
          mr_metrics_table[:latest_closed_at]
        end

        def apply_query_customization(query)
          inner_join(query, mr_metrics_table[:merge_request_id])
        end
      end
    end
  end
end
