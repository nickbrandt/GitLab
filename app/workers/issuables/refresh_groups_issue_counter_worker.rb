# frozen_string_literal: true

module Issuables
  class RefreshGroupsIssueCounterWorker
    include ApplicationWorker

    idempotent!
    urgency :low
    feature_category :issue_tracking

    def perform(group_ids = [])
      return if group_ids.empty?

      groups_with_ancestors = Gitlab::ObjectHierarchy
        .new(Group.by_id(group_ids))
        .base_and_ancestors

      refresh_cached_count(groups_with_ancestors)
    end

    private

    def refresh_cached_count(groups)
      groups.each do |group|
        Groups::OpenIssuesCountService.new(group).refresh_cache_over_threshold
      end
    end
  end
end
