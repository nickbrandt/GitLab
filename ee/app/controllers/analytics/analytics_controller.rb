# frozen_string_literal: true

class Analytics::AnalyticsController < Analytics::ApplicationController
  def index
    if Feature.disabled?(:group_level_productivity_analytics) && Gitlab::Analytics.productivity_analytics_enabled?
      redirect_to analytics_productivity_analytics_path
    elsif Gitlab::Analytics.cycle_analytics_enabled?
      redirect_to analytics_cycle_analytics_path
    else
      render_404
    end
  end
end
