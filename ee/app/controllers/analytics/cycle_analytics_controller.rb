# frozen_string_literal: true

class Analytics::CycleAnalyticsController < Analytics::ApplicationController
  check_feature_flag Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG
  increment_usage_counter Gitlab::UsageDataCounters::CycleAnalyticsCounter, :views, only: :show

  before_action do
    push_frontend_feature_flag(:customizable_cycle_analytics)
    push_frontend_feature_flag(:cycle_analytics_scatterplot_enabled)
  end
end
