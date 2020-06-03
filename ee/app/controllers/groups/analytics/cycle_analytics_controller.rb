# frozen_string_literal: true

class Groups::Analytics::CycleAnalyticsController < Analytics::CycleAnalyticsController
  layout 'group'

  before_action do
    render_403 unless can?(current_user, :read_group_cycle_analytics, @group)
  end
end
