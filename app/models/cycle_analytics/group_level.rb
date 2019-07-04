# frozen_string_literal: true

module CycleAnalytics
  class GroupLevel < Base
    def initialize(project: nil, options:)
      @project = project
      @options = options
    end

    def summary
      @summary ||= ::Gitlab::CycleAnalytics::GroupStageSummary.new(@options[:group],
                                                              from: @options[:from],
                                                              current_user: @options[:current_user],
                                                              options: @options).data
    end

    def permissions(user: nil)
      STAGES.each_with_object({}) do |stage, obj|
        obj[stage] = true
      end
    end

    def stats
      @stats ||= STAGES.map do |stage_name|
        self[stage_name].as_json(serializer: GroupAnalyticsStageSerializer)
      end
    end
  end
end
