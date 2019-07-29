# frozen_string_literal: true

class CycleAnalytics::StageEntity < Grape::Entity
  expose :name
  expose :legend
  expose :description
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

  def legend
    if object.model_to_query.eql?(Issue)
      _("Related Issues")
    elsif object.model_to_query.eql?(MergeRequest)
      _("Related Merged Requests")
    end
  end

  def description
    ''
  end
end
