# frozen_string_literal: true

module IncidentManagement
  module OncallScheduleHelper
    def oncall_schedule_data
      {
        'empty-oncall-schedules-svg-path' => image_path('illustrations/empty-state/empty-on-call.svg')
      }
    end
  end
end
