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
    expose :start_event_label_id, as: :label_id
    expose :start_event_label, as: :label, using: LabelEntity
  end
  expose :end_event, if: -> (stage) { stage.custom } do
    expose :end_event_identifier, as: :identifier
    expose :end_event_label_id, as: :label_id
    expose :end_event_label, as: :label, using: LabelEntity
  end

  DEFAULT_STAGE_DESCRIPTIONS = {
  }

  def legend
    if object.matches_with_stage_params?(Gitlab::CycleAnalytics::DefaultStages.params_for_test_stage)
      _("Related Jobs")
    elsif object.matches_with_stage_params?(Gitlab::CycleAnalytics::DefaultStages.params_for_staging_stage)
      _("Related Deployed Jobs")
    elsif object.model_to_query.eql?(Issue)
      _("Related Issues")
    elsif object.model_to_query.eql?(MergeRequest)
      _("Related Merged Requests")
    end
  end

  def description
    ''
  end
end
