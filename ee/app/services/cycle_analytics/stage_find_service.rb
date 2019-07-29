# frozen_string_literal: true

module CycleAnalytics
  class StageFindService
    def initialize(parent:, id:)
      @parent = parent
      @id = id
    end

    def execute
      @parent.cycle_analytics_stages.find(@id)
    end
  end
end
