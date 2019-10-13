# frozen_string_literal: true

# This module handles backward compatibility for approvals_before_merge column
module DeprecatedApprovalsBeforeMerge
  extend ActiveSupport::Concern

  include AfterCommitQueue

  included do
    after_save do
      run_after_commit do
        next unless saved_changes['approvals_before_merge']

        update_any_approver_rule
      end
    end
  end

  private

  def any_approver_rule
    strong_memoize(:any_approver_rule) do
      approval_rules.any_approver.safe_find_or_create_by(name: ApprovalRuleLike::ALL_MEMBERS)
    end
  end

  def update_any_approver_rule
    return if any_approver_rule.approvals_required == approvals_before_merge.to_i

    any_approver_rule.update_column(:approvals_required, approvals_before_merge.to_i)
  end
end
