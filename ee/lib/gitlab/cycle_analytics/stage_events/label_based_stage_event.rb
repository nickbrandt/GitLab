# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module StageEvents
      # Represents an event that is related to label creation or removal, this model requires a label provided by the user
      class LabelBasedStageEvent < StageEvent
        def label
          params.fetch(:label)
        end

        def label_id
          label.id
        end

        def self.label_based?
          true
        end
      end
    end
  end
end
