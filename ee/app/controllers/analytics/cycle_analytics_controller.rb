# frozen_string_literal: true

class Analytics::CycleAnalyticsController < Analytics::ApplicationController
  include RoutableActions
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include CycleAnalyticsParams

  before_action :whitelist_query_limiting, only: [:show]
  before_action :authorize_group_cycle_analytics!

  def show
    respond_to do |format|
      format.html
      format.json { render json: cycle_analytics_json }
    end
  end

  private

  def cycle_analytics_params
    return {} unless params[:cycle_analytics].present?

    params[:cycle_analytics].permit(:start_date, :group_id, :project_id, :namespace_id)
  end

  def cycle_analytics_json
    return {} unless cycle_analytics_params.key?(:group_id) || cycle_analytics_params.key?(:project_id)
    cycle_analytics = cycle_analytics_stats
    {
      summary: cycle_analytics.summary,
      stats: cycle_analytics.stats,
      permissions: cycle_analytics.permissions(user: current_user)
    }
  end

  def cycle_analytics_stats
    if cycle_analytics_params.key?(:group_id) && group
      ::CycleAnalytics::GroupLevel.new(options: options(cycle_analytics_params).merge(group: group))
    elsif cycle_analytics_params.key?(:project_id) && project
      ::CycleAnalytics::ProjectLevel.new(project: project, options: options(cycle_analytics_params))
    end
  end

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42671')
  end

  def authorize_group_cycle_analytics!
    unless can?(current_user, :read_group_cycle_analytics, group)
      return render_403
    end
  end

  def group
    find_routable!(Group, cycle_analytics_params[:group_id])
  end

  def project
    path = File.join(cycle_analytics_params[:namespace_id], cycle_analytics_params[:project_id])
    find_routable!(Project, path)
  end
end
