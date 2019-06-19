# frozen_string_literal: true

class Analytics::CycleAnalyticsEventsController < Analytics::ApplicationController
  include RoutableActions
  include CycleAnalyticsParams

  before_action do |controller|
    authorize_group_cycle_analytics! if controller.request.format.json?
    # routable_required if controller.request.format.json?
  end

  def issue
    render_events(:issue)
  end

  def plan
    render_events(:plan)
  end

  def code
    render_events(:code)
  end

  def test
    options(events_params)[:branch] = events_params[:branch_name]

    render_events(:test)
  end

  def review
    render_events(:review)
  end

  def staging
    render_events(:staging)
  end

  def production
    render_events(:production)
  end

  private

  def render_events(stage)
    respond_to do |format|
      format.html
      format.json { render json: { events: cycle_analytics ? cycle_analytics[stage].events : [] } }
    end
  end

  def cycle_analytics
    @cycle_analytics ||= cycle_analytics_events
  end

  def events_params
    return {} unless params[:events].present?

    params[:events].permit(:start_date, :branch_name, :group_id, :namespace_id, :project_id)
  end

  def cycle_analytics_events
    if project
      ::CycleAnalytics::ProjectLevel.new(project: project, options: options(events_params))
    elsif group
      ::CycleAnalytics::GroupLevel.new(options: options(events_params).merge(group: group))
    end
  end

  def authorize_group_cycle_analytics!
    puts namespace_or_group
    puts can?(current_user, :read_group_cycle_analytics, namespace_or_group)
    unless can?(current_user, :read_group_cycle_analytics, namespace_or_group)
      return render_403
    end
  end

  def routable_required
    puts 'here'
    unless group || project
      puts 'and here'
      return render_404
    end
  end

  def group
    @group ||= find_routable!(Group, events_params[:group_id])
  end

  def project
    return @project if @project
    path = File.join(events_params[:namespace_id].to_s, events_params[:project_id].to_s)
    @project ||= find_routable!(Project, path)
  end

  def namespace_or_group
    group || find_routable!(Group, events_params[:namespace_id])
  end
end
