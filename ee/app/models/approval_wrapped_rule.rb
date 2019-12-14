# frozen_string_literal: true

# A common state computation interface to wrap around ApprovalRuleLike models
class ApprovalWrappedRule
  extend Forwardable
  include Gitlab::Utils::StrongMemoize

  attr_reader :merge_request
  attr_reader :approval_rule

  def_delegators(:@approval_rule,
                 :regular?, :any_approver?, :code_owner?, :report_approver?,
                 :id, :name, :users, :groups, :code_owner, :source_rule,
                 :rule_type, :approvals_required)

  def self.wrap(merge_request, rule)
    if rule.any_approver?
      ApprovalWrappedAnyApproverRule.new(merge_request, rule)
    elsif rule.code_owner?
      ApprovalWrappedCodeOwnerRule.new(merge_request, rule)
    else
      ApprovalWrappedRule.new(merge_request, rule)
    end
  end

  def initialize(merge_request, approval_rule)
    @merge_request = merge_request
    @approval_rule = approval_rule
  end

  def project
    @merge_request.target_project
  end

  def approvers
    filter_approvers(@approval_rule.approvers)
  end

  # @return [Array<User>] all approvers related to this rule
  #
  # This is dynamically calculated unless it is persisted as `approved_approvers`.
  #
  # After merge, the approval state should no longer change.
  # We persist this so if project level rule is changed in the future,
  # return result won't be affected.
  #
  # For open MRs, it is dynamically calculated because:
  # - Additional complexity to add update hooks
  # - DB updating many MRs for one project rule change is inefficient
  def approved_approvers
    if merge_request.merged? && approval_rule.is_a?(ApprovalMergeRequestRule) && approval_rule.approved_approvers.present?
      return approval_rule.approved_approvers
    end

    strong_memoize(:approved_approvers) do
      overall_approver_ids = merge_request.approvals.map(&:user_id).to_set

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

  private

  def filter_approvers(approvers)
    filtered_approvers =
      ApprovalState.filter_author(approvers, merge_request)

    ApprovalState.filter_committers(filtered_approvers, merge_request)
  end
end
