# frozen_string_literal: true

module CycleAnalytics
  class StageUpdateService
    include CycleAnalytics::EventUpdateable

    def initialize(stage:, params: {})
      @stage = stage
      @params = params.dup
    end

    def execute
      handle_position_change

      if stage.default_stage? && params.has_key?(:hidden)
        stage.update(hidden: params[:hidden])
      else
        handle_custom_stage_update
      end

      stage
    end

    private

    attr_reader :stage, :params

    def handle_position_change
      move_before_id = params.delete(:move_before_id)
      move_after_id = params.delete(:move_after_id)

      if move_before_id
        before_stage = stage.class.relative_positioning_query_base(stage).find(move_before_id)
        stage.move_before(before_stage)
      elsif move_after_id
        after_stage = stage.class.relative_positioning_query_base(stage).find(move_after_id)
        stage.move_after(after_stage)
      end
    end

    def handle_custom_stage_update
      return if stage.default_stage?

      assign_event_parameters!

      stage.update(params)
    end
  end
end
