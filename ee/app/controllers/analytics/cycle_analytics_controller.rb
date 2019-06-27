# frozen_string_literal: true

class Analytics::CycleAnalyticsController < Analytics::ApplicationController
  include RoutableActions
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include CycleAnalyticsParams

  before_action :whitelist_query_limiting, only: [:show]
  before_action :authorize_group_cycle_analytics!

  before_action(:only => :show) do |controller|
    routable_required if controller.request.format.json?
  end

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
    cycle_analytics = cycle_analytics_stats
    {
      summary: cycle_analytics.summary,
      stats: cycle_analytics.stats,
      permissions: cycle_analytics.permissions(user: current_user)
    }
  end

  def cycle_analytics_stats
    if project
      ::CycleAnalytics::ProjectLevel.new(project: project, options: options(cycle_analytics_params))
    elsif group
      ::CycleAnalytics::GroupLevel.new(options: options(cycle_analytics_params).merge(group: group))
    end
  end

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42671')
  end

  def authorize_group_cycle_analytics!
    unless can?(current_user, :read_group_cycle_analytics, namespace_or_group)
      return render_403
    end
  end

  def routable_required
    return render_404 unless group || project
  end

  def group
    @group ||= find_routable!(Group, cycle_analytics_params[:group_id])
  end

  def project
    return @project if @project
    path = File.join(cycle_analytics_params[:namespace_id].to_s, cycle_analytics_params[:project_id].to_s)
    @project ||= find_routable!(Project, path)
  end

  def namespace_or_group
    group || find_routable!(Group, cycle_analytics_params[:namespace_id])
  end
end
