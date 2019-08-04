# frozen_string_literal: true

module CycleAnalytics
  class StageFindService
    def initialize(parent:, id:)
      @parent = parent
      @id = id
    end

    def execute
      if in_memory_default_stage?
        find_in_memory_stage_by_name!
      else
        parent.cycle_analytics_stages.find(id)
      end
    end

    private

    attr_reader :parent, :id

    def in_memory_default_stage?
      id.is_a?(String)
    end

    def find_in_memory_stage_by_name!
      raw_stage = Gitlab::CycleAnalytics::DefaultStages.all.find do |hash|
        hash[:name].eql?(id)
      end || raise(ActiveRecord::RecordNotFound)
      parent.cycle_analytics_stages.build(raw_stage)
    end
  end
end
