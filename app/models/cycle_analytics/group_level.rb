# frozen_string_literal: true

module CycleAnalytics
  class GroupLevel < Base
    def initialize(project: nil, options:)
      @project = project
      @options = options
    end

    def summary
      @summary ||= ::Gitlab::CycleAnalytics::GroupStageSummary.new(@project,
                                                              from: @options[:from],
                                                              current_user: @options[:current_user]).data
    end

    def permissions(user: nil)
      STAGES.each_with_object({}) do |stage, obj|
        obj[stage] = true
      end
    end

    private

    def stats_per_stage
      STAGES.map do |stage_name|
        self[stage_name].as_json(serializer: GroupAnalyticsStageSerializer)
      end
    end
  end
end
