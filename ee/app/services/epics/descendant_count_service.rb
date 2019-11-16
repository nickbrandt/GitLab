# frozen_string_literal: true

module Epics
  class DescendantCountService
    include Gitlab::Utils::StrongMemoize

    attr_reader :epic, :current_user

    def initialize(epic, current_user)
      @epic = epic
      @current_user = current_user
    end

    def opened_epics
      epics_count.fetch(Epic.state_ids[:opened], 0)
    end

    def closed_epics
      epics_count.fetch(Epic.state_ids[:closed], 0)
    end

    def opened_issues
      issues_count.fetch('opened', 0)
    end

    def closed_issues
      issues_count.fetch('closed', 0)
    end

    private

    def epics_count
      strong_memoize(:epics_count) do
        accessible_epics.id_not_in(epic.id).counts_by_state
      end
    end

    def issues_count
      strong_memoize(:issue_counts) do
        IssuesFinder.new(current_user).execute.in_epics(accessible_epics).counts_by_state
      end
    end

    def accessible_epics
      strong_memoize(:epics) do
        epics = epic.base_and_descendants
        groups = Epic.groups_user_can_read_epics(epics, current_user)
        epics.in_selected_groups(groups)
      end
    end
  end
end
