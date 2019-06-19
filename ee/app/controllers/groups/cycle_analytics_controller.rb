# frozen_string_literal: true

class Groups::CycleAnalyticsController < Groups::ApplicationController
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include CycleAnalyticsParams

  before_action :group
  before_action :whitelist_query_limiting, only: [:show]
  before_action :authorize_group_cycle_analytics!


  def show
    respond_to do |format|
      format.json { render json: cycle_analytics_json }
    end
  end

  private

  def cycle_analytics_params
    return {} unless params[:cycle_analytics].present?

    params[:cycle_analytics].permit(:start_date)
  end

  def cycle_analytics_json
    cycle_analytics = cycle_analytics_stats
    {
      summary: cycle_analytics.summary,
      stats: cycle_analytics.stats,
      permissions: cycle_analytics.permissions(user: current_user)
    }
  end

  def cycle_analytics_stats
    ::CycleAnalytics::GroupLevel.new(options: options(cycle_analytics_params).merge(group: group))
  end

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42671')
  end

  def authorize_group_cycle_analytics!
    unless can?(current_user, :read_group_cycle_analytics, group)
      return render_403
    end
  end
end
