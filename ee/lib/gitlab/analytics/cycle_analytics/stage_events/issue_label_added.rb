# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        class IssueLabelAdded < LabelBasedStageEvent
          def self.name
            s_("CycleAnalyticsEvent|Issue label was added")
          end

          def self.identifier
            :issue_label_added
          end

          def object_type
            Issue
          end
        end
      end
    end
  end
end
