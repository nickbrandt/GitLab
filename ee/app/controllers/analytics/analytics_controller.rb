# frozen_string_literal: true

class Analytics::AnalyticsController < Analytics::ApplicationController
  def index
    if Gitlab::Analytics.cycle_analytics_enabled?
      redirect_to analytics_cycle_analytics_path
    else
      render_404
    end
  end
end
