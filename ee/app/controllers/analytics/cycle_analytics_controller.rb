# frozen_string_literal: true

class Analytics::CycleAnalyticsController < Analytics::ApplicationController
  check_feature_flag Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG
  increment_usage_counter Gitlab::UsageDataCounters::CycleAnalyticsCounter, :views, only: :show
end
