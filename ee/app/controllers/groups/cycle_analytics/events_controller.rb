# frozen_string_literal: true

class Groups::CycleAnalytics::EventsController < Groups::ApplicationController
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::TextHelper
  include CycleAnalyticsParams

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
    @cycle_analytics ||= ::CycleAnalytics::GroupLevel.new(group: group, options: options(cycle_analytics_group_params))
  end

  def authorize_group_cycle_analytics!
    unless can?(current_user, :read_group_cycle_analytics, group)
      render_403
    end
  end
end
