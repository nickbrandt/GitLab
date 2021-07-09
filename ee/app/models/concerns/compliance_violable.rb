# frozen_string_literal: true

# Concern to encapsulate logic of MergeRequests that can
# violate certain rules.
module ComplianceViolable
  extend ActiveSupport::Concern

  # Can we put in an `after merge` callback here so that all we need to do is include it in the model?

  MINIMUM_NUMBER_OF_APPROVERS = 2

  def approved_by_author?
    approver_users.include?(author)
  end

  def approved_by_committer?
    (approver_users & committers).to_a.any?
  end

  def approved_by_insufficient_users?
    approvers.count < MINIMUM_NUMBER_OF_APPROVERS
  end
end
