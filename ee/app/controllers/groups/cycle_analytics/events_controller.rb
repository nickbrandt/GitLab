# frozen_string_literal: true

class Groups::CycleAnalytics::EventsController < Groups::ApplicationController
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include CycleAnalyticsParams

  before_action :group
  before_action :whitelist_query_limiting, only: [:show]
  before_action :authorize_group_cycle_analytics!

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
      format.json { render json: { events: cycle_analytics[stage].events } }
    end
  end

  def cycle_analytics
    @cycle_analytics ||= cycle_analytics_events
  end

  def events_params
    return {} unless params[:events].present?

    params[:events].permit(:start_date, :branch_name, :project_ids)
  end

  def cycle_analytics_events
    ::CycleAnalytics::GroupLevel.new(options: options(events_params).merge(group_cycle_analytics_params))
  end

  def authorize_group_cycle_analytics!
    unless can?(current_user, :read_group_cycle_analytics, group)
      render_403
    end
  end

  def group_cycle_analytics_params
    params = { group: group }
    params.merge(projects: cycle_analytics_params[:project_ids]) if cycle_analytics_params[:project_ids]
    params
  end
end
