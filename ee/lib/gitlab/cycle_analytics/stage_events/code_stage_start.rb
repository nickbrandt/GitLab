# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      class CodeStageStart < SimpleStageEvent
        def self.identifier
          :code_stage_start
        end

        def object_type
          MergeRequest
        end

        def timestamp_projection
          issue_metrics_table[:first_mentioned_in_commit_at]
        end

        def apply_query_customization(query)
          q = inner_join(mr_table, mr_closing_issues_table[:merge_request_id])
          q = inner_join(q, issue_metrics_table[:issue_id], mr_closing_issues_table[:issue_id])
          q
        end

        def self.default_stage_event?
          true
        end
      end
    end
  end
end
