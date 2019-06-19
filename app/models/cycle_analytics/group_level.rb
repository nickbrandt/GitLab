# frozen_string_literal: true

module CycleAnalytics
  class GroupLevel < Base
    def initialize(project: nil, projects:, options:)
      @projects = projects
      @options = options
    end

    def summary
      @summary ||= ::Gitlab::CycleAnalytics::GroupStageSummary.new(@project,
                                                              from: @options[:from],
                                                              current_user: @options[:current_user]).data
    end

    def permissions(user:)
      STAGES.each_with_object({}) do |stage, obj|
        obj[stage] = true
      end
    end
  end
end
