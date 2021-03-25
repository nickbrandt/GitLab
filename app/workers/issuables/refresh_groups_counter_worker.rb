# frozen_string_literal: true

module Issuables
  class RefreshGroupsCounterWorker
    include ApplicationWorker

    idempotent!
    urgency :low
    feature_category :issue_tracking

    # rubocop: disable CodeReuse/ActiveRecord
    def perform(type, current_user_id, group_ids = [])
      return unless group_ids.any? && issue_type?(type)

      current_user = User.find(current_user_id)
      groups_with_ancestors = Gitlab::ObjectHierarchy.new(Group.where(id: group_ids)).base_and_ancestors

      refresh_cached_count(type, current_user, groups_with_ancestors)
    rescue ActiveRecord::RecordNotFound => e
      Gitlab::ErrorTracking.log_exception(e, user_id: current_user_id)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def refresh_cached_count(type, user, groups)
      groups.each do |group|
        count_service = count_service_class(type)&.new(group, user)
        next unless count_service&.count_stored?

        count_service.refresh_cache_over_threshold
      end
    end

    def count_service_class(type)
      Groups::OpenIssuesCountService if issue_type?(type)
    end

    def issue_type?(type)
      type.to_sym == :issue
    end
  end
end
