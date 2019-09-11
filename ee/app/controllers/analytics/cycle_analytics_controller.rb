# frozen_string_literal: true

class Analytics::CycleAnalyticsController < Analytics::ApplicationController
  check_feature_flag Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG
end
