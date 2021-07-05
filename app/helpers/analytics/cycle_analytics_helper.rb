# frozen_string_literal: true

module Analytics
  module CycleAnalyticsHelper
    def cycle_analytics_default_stage_config
      Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map do |stage_params|
        Analytics::CycleAnalytics::StagePresenter.new(stage_params)
      end
    end

    def cycle_analytics_default_group_labels(labels)
      LabelSerializer.new.represent_appearance(labels)
    end
  end
end
