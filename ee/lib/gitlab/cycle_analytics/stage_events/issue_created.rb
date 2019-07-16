# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      class IssueCreated < SimpleStageEvent
        def self.identifier
          :issue_created
        end

        def object_type
          Issue
        end

        def timestamp_projection
          issue_table[:created_at]
        end
      end
    end
  end
end
