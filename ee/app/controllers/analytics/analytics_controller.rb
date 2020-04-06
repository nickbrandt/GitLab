# frozen_string_literal: true

class Analytics::AnalyticsController < Analytics::ApplicationController
  def index
    if can?(current_user, :read_instance_statistics)
      redirect_to instance_statistics_dev_ops_score_index_path
    else
      render_404
    end
  end
end
