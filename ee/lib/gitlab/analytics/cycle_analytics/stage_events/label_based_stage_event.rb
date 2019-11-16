# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      module StageEvents
        # Represents an event that is related to label creation or removal, this model requires a label provided by the user
        class LabelBasedStageEvent < StageEvent
          def label_based?
            true
          end
        end
      end
    end
  end
end
