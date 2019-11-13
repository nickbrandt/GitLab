# frozen_string_literal: true

require 'forwardable'

# A state object to centralize logic related to various approval related states.
# This reduce interface footprint on MR and allows easier cache invalidation.
class ApprovalState
  extend Forwardable
  include ::Gitlab::Utils::StrongMemoize

  attr_reader :merge_request, :project

  def_delegators :@merge_request, :merge_status, :approved_by_users, :approvals, :approval_feature_available?
  alias_method :approved_approvers, :approved_by_users

  def initialize(merge_request)
    @merge_request = merge_request
    @project = merge_request.target_project
  end

  # Excludes the author if 'author-approval' is explicitly disabled on project settings.
  def self.filter_author(users, merge_request)
    return users if merge_request.target_project.merge_requests_author_approval?

    if users.is_a?(ActiveRecord::Relation) && !users.loaded?
      users.where.not(id: merge_request.author_id)
    else
      users - [merge_request.author]
    end
  end

  # Excludes the author if 'committers-approval' is explicitly disabled on project settings.
  def self.filter_committers(users, merge_request)
    return users unless merge_request.target_project.merge_requests_disable_committers_approval?

    if users.is_a?(ActiveRecord::Relation) && !users.loaded?
      users.where.not(id: merge_request.committers.select(:id))
    else
      users - merge_request.committers
    end
  end

  def wrapped_approval_rules
    strong_memoize(:wrapped_approval_rules) do
      next [] unless approval_feature_available?

      result = use_fallback? ? [fallback_rule] : regular_rules
      result += code_owner_rules
      result += report_approver_rules
      result
    end
  end

  def has_non_fallback_rules?
    has_regular_rule_with_approvers? || code_owner_rules.present? || report_approver_rules.present?
  end

  # Use the fallback rule if regular rules are empty
  def use_fallback?
    !has_regular_rule_with_approvers?
  end

  def fallback_rule
    @fallback_rule ||= ApprovalMergeRequestFallback.new(merge_request)
  end

  # Determines which set of rules to use (MR or project)
  def approval_rules_overwritten?
    regular_merge_request_rules.any? { |rule| rule.approvers.present? } ||
      (project.can_override_approvers? && merge_request.approvals_before_merge.present?)
  end
  alias_method :approvers_overwritten?, :approval_rules_overwritten?

  def approval_needed?
    return false unless project.feature_available?(:merge_request_approvers)

    wrapped_approval_rules.any? { |rule| rule.approvals_required > 0 }
  end

  def approved?
    strong_memoize(:approved) do
      wrapped_approval_rules.all?(&:approved?)
    end
  end

  def any_approver_allowed?
    !has_regular_rule_with_approvers? || approved?
  end

  def approvals_required
    strong_memoize(:approvals_required) do
      wrapped_approval_rules.sum(&:approvals_required)
    end
  end

  # Number of approvals remaining (excluding existing approvals) before the MR is
  # considered approved.
  def approvals_left
    strong_memoize(:approvals_left) do
      wrapped_approval_rules.sum(&:approvals_left)
    end
  end

  def approval_rules_left
    wrapped_approval_rules.reject(&:approved?)
  end

  def approvers
    strong_memoize(:approvers) { filtered_approvers(target: :approvers) }
  end

  # @param regular [Boolean]
  # @param code_owner [Boolean]
  # @param report_approver [Boolean]
  # @param target [:approvers, :users]
  # @param unactioned [Boolean]
  def filtered_approvers(regular: true, code_owner: true, report_approver: true, target: :approvers, unactioned: false)
    rules = []
    rules.concat(regular_rules) if regular
    rules.concat(code_owner_rules) if code_owner
    rules.concat(report_approver_rules) if report_approver

    filter_approvers(rules.flat_map(&target), unactioned: unactioned)
  end

  def unactioned_approvers
    strong_memoize(:unactioned_approvers) { approvers - approved_approvers }
  end

  # TODO order by relevance
  def suggested_approvers(current_user:)
    # Ignore approvers from rules containing hidden groups
    rules = wrapped_approval_rules.reject do |rule|
      ApprovalRules::GroupFinder.new(rule, current_user).contains_hidden_groups?
    end

    filter_approvers(rules.flat_map(&:approvers), unactioned: true)
  end

  def can_approve?(user)
    return false unless user
    return false unless user.can?(:approve_merge_request, merge_request)

    return true if unactioned_approvers.include?(user)
    return false unless any_approver_allowed?
    # Users can only approve once.
    return false if approvals.where(user: user).any?
    # At this point, follow self-approval rules. Otherwise authors must
    # have been in the list of unactioned_approvers to have been approved.
    return false if !authors_can_approve? && merge_request.author == user
    return false if !committers_can_approve? && merge_request.committers.include?(user)

    true
  end

  def has_approved?(user)
    return false unless user

    approved_approvers.include?(user)
  end

  def authors_can_approve?
    project.merge_requests_author_approval?
  end

  def committers_can_approve?
    !project.merge_requests_disable_committers_approval?
  end

  # TODO: remove after #1979 is closed
  # This is a temporary method for backward compatibility
  # before introduction of approval rules.
  # This avoids re-queries.
  def first_regular_rule
    strong_memoize(:first_regular_rule) do
      regular_rules.first
    end
  end

  private

  def filter_approvers(approvers, unactioned:)
    approvers = approvers.uniq
    approvers -= approved_approvers if unactioned
    approvers = self.class.filter_author(approvers, merge_request)

    self.class.filter_committers(approvers, merge_request)
  end

  def has_regular_rule_with_approvers?
    regular_rules.any? { |rule| rule.approvers.present? }
  end

  def regular_rules
    strong_memoize(:regular_rules) do
      rules = approval_rules_overwritten? ? regular_merge_request_rules : regular_project_rules

      unless project.multiple_approval_rules_available?
        rules = rules[0, 1]
      end

      wrap_rules(rules)
    end
  end

  def regular_merge_request_rules
    @regular_merge_request_rules ||= merge_request.approval_rules.select(&:regular?).sort_by(&:id)
  end

  def regular_project_rules
    @regular_project_rules ||= project.visible_regular_approval_rules.to_a
  end

  def code_owner_rules
    strong_memoize(:code_owner_rules) do
      wrap_rules(merge_request.approval_rules.select(&:code_owner?))
    end
  end

  def report_approver_rules
    strong_memoize(:report_approver_rules) do
      wrap_rules(merge_request.approval_rules.select(&:report_approver?))
    end
  end

  def wrap_rules(rules)
    rules.map { |rule| ApprovalWrappedRule.new(merge_request, rule) }
  end
end
