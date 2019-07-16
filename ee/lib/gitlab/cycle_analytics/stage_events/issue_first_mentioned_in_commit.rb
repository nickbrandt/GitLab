# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      class IssueFirstMentionedInCommit < SimpleStageEvent
        def self.identifier
          :issue_first_mentioned_in_commit
        end

        def object_type
          Issue
        end

        def timestamp_projection
          issue_metrics_table[:first_mentioned_in_commit_at]
        end

        def apply_query_customization(query)
          inner_join(query, issue_metrics_table[:issue_id])
        end
      end
    end
  end
end
