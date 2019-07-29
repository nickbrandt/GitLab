# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      class IssueFirstAssociatedWithMilestone < SimpleStageEvent
        def self.name
          s_("CycleAnalyticsEvent|Issue first associated with a milestone")
        end

        def self.identifier
          :issue_first_associated_with_milestone
        end

        def object_type
          Issue
        end

        def timestamp_projection
          issue_metrics_table[:first_associated_with_milestone_at]
        end

        def apply_query_customization(query)
          inner_join(query, issue_metrics_table[:issue_id])
        end
      end
    end
  end
end
