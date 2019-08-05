# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      class MergeRequestLabelAdded < LabelBasedStageEvent
        def self.name
          s_("CycleAnalyticsEvent|Merge request label was added")
        end

        def self.identifier
          :merge_request_label_added
        end

        def object_type
          MergeRequest
        end

        def timestamp_projection
          subquery[:created_at]
        end

        def apply_query_customization(query)
          inner_join(query, subquery[:merge_request_id]).where(subquery[:row_id].eq(1))
        end

        def subquery
          resource_label_events_with_subquery(:merge_request_id, label, ::ResourceLabelEvent.actions[:add], :asc, 'label_added_for_first_time')
        end
      end
    end
  end
end
