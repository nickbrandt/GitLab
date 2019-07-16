# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      class PlanStageStart < SimpleStageEvent
        def self.identifier
          :plan_stage_start
        end

        def object_type
          Issue
        end

        def timestamp_projection
          Arel::Nodes::NamedFunction.new('COALESCE', [
            issue_metrics_table[:first_associated_with_milestone_at],
            issue_metrics_table[:first_added_to_board_at]
          ])
        end

        def apply_query_customization(query)
          q = inner_join(query, issue_metrics_table[:issue_id])
          q.where(issue_metrics_table[:first_added_to_board_at].not_eq(nil).or(issue_metrics_table[:first_associated_with_milestone_at].not_eq(nil))).where(issue_metrics_table[:first_mentioned_in_commit_at].not_eq(nil))
        end
      end

      def self.default_stage_event?
        true
      end
    end
  end
end
