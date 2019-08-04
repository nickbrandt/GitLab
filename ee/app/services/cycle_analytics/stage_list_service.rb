# frozen_string_literal: true

module CycleAnalytics
  class StageListService
    def initialize(parent:, allowed_to_customize_stages: false)
      @parent = parent
      @allowed_to_customize_stages = allowed_to_customize_stages
    end

    def execute
      persisted_stages.any? ? persisted_stages : build_stages
    end

    private

    attr_reader :parent, :allowed_to_customize_stages

    def persisted_stages
      @persisted_stages ||= parent.cycle_analytics_stages.ordered
    end

    def build_stages
      stages = Gitlab::CycleAnalytics::DefaultStages.all.map do |params|
        parent.cycle_analytics_stages.build(params)
      end

      if allowed_to_customize_stages
        stages.each(&:save!)
      end

      stages
    end
  end
end
