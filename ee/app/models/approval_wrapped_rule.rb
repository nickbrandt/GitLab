# frozen_string_literal: true

# A common state computation interface to wrap around ApprovalRuleLike models
class ApprovalWrappedRule
  extend Forwardable
  include Gitlab::Utils::StrongMemoize

  attr_reader :merge_request
  attr_reader :approval_rule

  def_delegators :@approval_rule, :id, :name, :users, :groups, :approvals_required, :code_owner, :source_rule, :rule_type

  def initialize(merge_request, approval_rule)
    @merge_request = merge_request
    @approval_rule = approval_rule
  end

  def project
    @merge_request.target_project
  end

  def approvers
    ApprovalState.filter_author(@approval_rule.approvers, merge_request)
  end

  # @return [Array<User>] all approvers related to this rule
  #
  # This is dynamically calculated when MR is open, but is persisted in DB after MR is merged.
  #
  # After merge, the approval state should no longer change.
  # Persisting instead of recomputing dynamically guarantees this even
  # if project level rule ever adds/removes approvers after the merge.
  #
  # For open MRs, it is still dynamically calculated instead of persisted because
  # - Additional complexity to add update hooks
  # - DB updating many MRs for one project rule change is inefficient
  def approved_approvers
    return approval_rule.approved_approvers if merge_request.merged?

    strong_memoize(:approved_approvers) do
      overall_approver_ids = merge_request.approvals.map(&:user_id)

      approvers.select do |approver|
        overall_approver_ids.include?(approver.id)
      end
    end
  end

  def approved?
    strong_memoize(:approved) do
      approvals_left <= 0 || unactioned_approvers.size <= 0
    end
  end

  # Number of approvals remaining (excluding existing approvals)
  # before the rule is considered approved.
  #
  # If there are fewer potential approvers than approvals left,
  # users should either reduce `approvals_required`
  # and/or allow MR authors to approve their own merge
  # requests (in case only one approval is needed).
  def approvals_left
    strong_memoize(:approvals_left) do
      approvals_left_count = approvals_required - approved_approvers.size

      [approvals_left_count, 0].max
    end
  end

  def unactioned_approvers
    approvers - approved_approvers
  end
end
