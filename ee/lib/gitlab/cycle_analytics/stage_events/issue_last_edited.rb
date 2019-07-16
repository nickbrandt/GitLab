# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      class IssueLastEdited < SimpleStageEvent
        def self.identifier
          :issue_last_edited
        end

        def object_type
          Issue
        end

        def timestamp_projection
          issue_table[:last_edited_at]
        end
      end
    end
  end
end
