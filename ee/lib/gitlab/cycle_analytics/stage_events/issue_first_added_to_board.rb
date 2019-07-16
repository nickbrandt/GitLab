# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      class IssueFirstAddedToBoard < SimpleStageEvent
        def self.identifier
          :issue_first_added_to_board
        end

        def object_type
          Issue
        end

        def timestamp_projection
          issue_metrics_table[:first_added_to_board_at]
        end

        def apply_query_customization(query)
          inner_join(query, issue_metrics_table[:issue_id])
        end
      end
    end
  end
end
