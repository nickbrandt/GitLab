# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      class IssueLabelAdded < LabelBasedStageEvent
        def self.name
          s_("CycleAnalyticsEvent|Issue label was assigned")
        end

        def self.identifier
          :issue_label_added
        end

        def object_type
          Issue
        end

        def timestamp_projection
          subquery[:created_at]
        end

        def apply_query_customization(query)
          inner_join(query, subquery[:issue_id]).where(subquery[:row_id].eq(1))
        end

        def subquery
          resource_label_events_with_subquery(:issue_id, label, ResourceLabelEvent.actions[:add], :asc, 'label_added_for_first_time')
        end
      end
    end
  end
end
