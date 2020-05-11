# frozen_string_literal: true

class Analytics::CycleAnalyticsController < Analytics::ApplicationController
  include CycleAnalyticsParams

  check_feature_flag Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG
  increment_usage_counter Gitlab::UsageDataCounters::CycleAnalyticsCounter, :views, only: :show

  before_action do
    push_frontend_feature_flag(:cycle_analytics_scatterplot_enabled, default_enabled: true)
    push_frontend_feature_flag(:cycle_analytics_scatterplot_median_enabled, default_enabled: true)
  end

  before_action :load_group, only: :show
  before_action :load_project, only: :show
  before_action :build_request_params, only: :show

  def build_request_params
    @request_params ||= Gitlab::Analytics::CycleAnalytics::RequestParams.new(allowed_params.merge(group: @group), current_user: current_user)
  end

  def allowed_params
    params.permit(
      :created_after,
      :created_before,
      project_ids: []
    )
  end
end
