# frozen_string_literal: true

module MergeRequests
  # Used to filter MergeRequests collections by approvers
  class ByApprovalsFinder
    attr_reader :usernames, :ids

    def initialize(usernames, ids)
      @usernames = usernames.to_a.map(&:to_s)
      @ids = ids
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
      ids.to_s.downcase == label || usernames.map(&:downcase).include?(label)
    end

    # Merge Requests without any approval
    def without_approvals(items)
      items
        .left_outer_joins(:approvals)
        .joins('LEFT OUTER JOIN approvals ON approvals.merge_request_id = merge_requests.id')
        .where(approvals: { id: nil })
    end

    # Merge Requests with any number of approvals
    def with_any_approvals(items)
      items.select_from_union([
        items.joins(:approvals),
        items.joins('INNER JOIN approvals ON approvals.merge_request_id = merge_requests.id')
      ])
    end

    # Merge Requests approved by given usernames
    def find_approved_by_names(items)
      find_approved_by_query(items, :username, usernames)
    end

    # Merge Requests approved by given user IDs
    def find_approved_by_ids(items)
      find_approved_by_query(items, :id, ids)
    end

    def find_approved_by_query(items, field, values)
      items
        .joins(:approvals)
        .joins(approvals: [:user])
        .where(users: { field => values })
        .group('merge_requests.id')
        .having("COUNT(users.id) = ?", values.size)
    end
  end
end
