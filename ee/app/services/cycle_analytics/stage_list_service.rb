# frozen_string_literal: true

module CycleAnalytics
  class StageListService
    def initialize(parent:, allowed_to_customize_stages: false)
      @parent = parent
      @allowed_to_customize_stages = allowed_to_customize_stages
    end

    def execute
      persisted_stages.any? ? persisted_stages : build_default_stages
    end

    private

    attr_reader :parent, :allowed_to_customize_stages

    def persisted_stages
      @persisted_stages ||= parent.cycle_analytics_stages.ordered
    end

    def build_default_stages
      stages = Gitlab::CycleAnalytics::DefaultStages.all.map do |params|
        parent.cycle_analytics_stages.build(params)
      end

      # if customization is allowed all stages must be persisted
      stages.each(&:save!) if allowed_to_customize_stages
      stages
    end
  end
end
