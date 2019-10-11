# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class StageEntity < Grape::Entity
      expose :title
      expose :legend
      expose :description
      expose :id
      expose :custom
      expose :start_event_identifier, if: :custom?
      expose :end_event_identifier, if: :custom?

      def id
        object.id || object.name
      end
    end
  end
end
