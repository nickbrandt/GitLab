# frozen_string_literal: true

module CycleAnalytics
  class StageCreateService
    include CycleAnalytics::EventUpdateable

    def initialize(parent:, params: {})
      @parent = parent
      @params = params.dup
      @stage = parent.cycle_analytics_stages.build
    end

    def execute
      assign_event_parameters!
      stage.tap { |s| s.update(params) }
    end

    private

    attr_reader :parent, :params, :stage
  end
end
