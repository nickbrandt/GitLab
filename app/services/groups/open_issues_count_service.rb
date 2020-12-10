# frozen_string_literal: true

module Groups
  # Service class for counting and caching the number of open issues of a group.
  class OpenIssuesCountService < OpenIssuesCountBaseService
    include Gitlab::Utils::StrongMemoize

    PUBLIC_COUNT_KEY = 'group_public_open_issues_count'
    TOTAL_COUNT_KEY = 'group_total_open_issues_count'

    def cache_options
      super.merge({ expires_in: 24.hours })
    end

    def self.query(group, user: nil, public_only: true)
      IssuesFinder.new(user, group_id: group.id, state: 'opened', non_archived: true, include_subgroups: true, public_only: public_only).execute
    end
  end
end
