# frozen_string_literal: true

module Milestones
  class DestroyService < Milestones::BaseService
    def execute(milestone)
      Milestone.transaction do
        log_destroy_event_for(milestone)

        milestone.destroy
      end
    end

    private

    def log_destroy_event_for(milestone)
      return if milestone.group_milestone?

      event = event_service.destroy_milestone(milestone, current_user)
      event.update!(target_id: nil)
    end
  end
end
