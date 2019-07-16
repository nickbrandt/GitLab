# frozen_string_literal: true

class CycleAnalytics::StageEntity < Grape::Entity
  expose :name
  expose :id
  expose :relative_position, as: :position
  expose :hidden
  expose :custom
  expose :start_event, if: -> (stage) { stage.custom } do
    expose :start_event_identifier, as: :identifier
  end
  expose :end_event, if: -> (stage) { stage.custom } do
    expose :end_event_identifier, as: :identifier
  end
end
