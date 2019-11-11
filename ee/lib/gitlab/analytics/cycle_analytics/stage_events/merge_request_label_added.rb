# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class MergeRequestLabelAdded < LabelBasedStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Merge Request label was added")
          end

          def self.identifier
            :merge_request_label_added
          end

          def object_type
            MergeRequest
          end
        end
      end
    end
  end
end
