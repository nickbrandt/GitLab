# frozen_string_literal: true

class Groups::Analytics::CycleAnalyticsController < Analytics::CycleAnalyticsController
  include Analytics::UniqueVisitsHelper

  layout 'group'

  before_action do
    render_403 unless can?(current_user, :read_group_cycle_analytics, @group)
  end

  track_unique_visits :show, target_id: 'g_analytics_valuestream'
end
