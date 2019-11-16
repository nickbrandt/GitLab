# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class MergeRequestLabelRemoved < LabelBasedStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Merge Request label was removed")
          end

          def self.identifier
            :merge_request_label_removed
          end

          def object_type
            MergeRequest
          end
        end
      end
    end
  end
end
