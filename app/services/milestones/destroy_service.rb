# frozen_string_literal: true

module Milestones
  class DestroyService < Milestones::BaseService
    def execute(milestone)
      Milestone.transaction do
        update_issues(milestone)
        update_merge_requests(milestone)
        log_destroy_event_for(milestone)
        update_events(milestone)

        milestone.destroy
      end
    end

    private

    def update_issues(milestone)
      milestone.issues.each do |issue|
        Issues::UpdateService.new(parent, current_user, update_params).execute(issue)
      end
    end

    def update_merge_requests(milestone)
      milestone.merge_requests.each do |merge_request|
        MergeRequests::UpdateService.new(parent, current_user, update_params).execute(merge_request)
      end
    end

    def log_destroy_event_for(milestone)
      return if milestone.group_milestone?

      event_service.destroy_milestone(milestone, current_user)
    end

    def update_events(milestone)
      # TODO: why don't we update events in case of group milestone?
      return if milestone.group_milestone?

      Event.for_milestone_id(milestone.id).each do |event|
        event.target_id = nil
        event.save
      end
    end

    def update_params
      { milestone: nil, skip_milestone_email: true }
    end
  end
end
