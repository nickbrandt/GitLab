# frozen_string_literal: true

module Issuables
  class RefreshGroupsIssueCounterWorker
    include ApplicationWorker

    idempotent!
    urgency :low
    feature_category :issue_tracking

    def perform(current_user_id, group_ids = [])
      return if group_ids.empty?

      current_user = User.find(current_user_id)
      groups_with_ancestors = Gitlab::ObjectHierarchy
        .new(Group.by_id(group_ids))
        .base_and_ancestors
        .with_route

      refresh_cached_count(current_user, groups_with_ancestors)
    rescue ActiveRecord::RecordNotFound => e
      Gitlab::ErrorTracking.log_exception(e, user_id: current_user_id)
    end

    private

    def refresh_cached_count(user, groups)
      groups.each do |group|
        Groups::OpenIssuesCountService.new(group, user).refresh_cache_over_threshold
      end
    end
  end
end
