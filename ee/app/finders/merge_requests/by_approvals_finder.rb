# frozen_string_literal: true

module MergeRequests
  # Used to filter MergeRequests collections by approvers
  class ByApprovalsFinder
    attr_reader :usernames, :ids

    def initialize(usernames, ids)
      @usernames = Array(usernames).map(&:to_s).uniq
      @ids = Array(ids).uniq
    end

    def execute(items)
      if by_no_approvals?
        without_approvals(items)
      elsif by_any_approvals?
        with_any_approvals(items)
      elsif ids.present?
        find_approved_by_ids(items)
      elsif usernames.present?
        find_approved_by_names(items)
      else
        items
      end
    end

    private

    # Is param using special condition: "None" ?
    def by_no_approvals?
      includes_custom_label?(IssuableFinder::FILTER_NONE)
    end

    # Is param using special condition: "Any" ?
    def by_any_approvals?
      includes_custom_label?(IssuableFinder::FILTER_ANY)
    end

    def includes_custom_label?(label)
      ids.first.to_s.downcase == label || usernames.map(&:downcase).include?(label)
    end

    # Merge Requests without any approval
    def without_approvals(items)
      items.without_approvals
    end

    # Merge Requests with any number of approvals
    def with_any_approvals(items)
      items.select_from_union([
        items.with_approvals
      ])
    end

    # Merge Requests approved by given usernames
    def find_approved_by_names(items)
      items.approved_by_users_with_usernames(*usernames)
    end

    # Merge Requests approved by given user IDs
    def find_approved_by_ids(items)
      items.approved_by_users_with_ids(*ids)
    end
  end
end
