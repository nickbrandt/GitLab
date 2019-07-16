# frozen_string_literal: true

module CycleAnalytics
  class StageListService
    def initialize(parent:)
      @parent = parent
    end

    def execute
      persisted_stages.any? ? persisted_stages : create_default_stages
    end

    private

    def persisted_stages
      @persisted_stages ||= @parent.cycle_analytics_stages.ordered
    end

    def create_default_stages
      @parent.cycle_analytics_stages = Gitlab::CycleAnalytics::DefaultStages.all.map do |params|
        @parent.cycle_analytics_stages.build(params)
      end
    end
  end
end
