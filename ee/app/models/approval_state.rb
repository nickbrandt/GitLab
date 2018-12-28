# frozen_string_literal: true

require 'forwardable'

# A state object to centralize logic related to various approval related states.
# This reduce interface footprint on MR and allows easier cache invalidation.
class ApprovalState
  extend Forwardable
  include ::Gitlab::Utils::StrongMemoize

  attr_reader :merge_request, :project

  def_delegators :@merge_request, :merge_status, :approved_by_users
  alias_method :approved_approvers, :approved_by_users

  def initialize(merge_request)
    @merge_request = merge_request
    @project = merge_request.target_project
  end

  # Excludes the author if 'self-approval' isn't explicitly enabled on project settings.
  def self.filter_author(users, merge_request)
    return users unless merge_request.author_id
    return users if merge_request.target_project.merge_requests_author_approval?

    if users.is_a?(ActiveRecord::Relation) && !users.loaded?
      users.where.not(id: merge_request.author_id)
    else
      users.dup
      users.delete(merge_request.author)
      users
    end
  end

  def wrapped_approval_rules
    strong_memoize(:wrapped_approval_rules) do
      regular_rules + code_owner_rules
    end
  end

  def approval_rules_overwritten?
    merge_request.approval_rules.regular.exists?
  end

  def approval_needed?
    return false unless project.feature_available?(:merge_request_approvers)

    !approved?
  end

  def approved?
    strong_memoize(:approved) do
      wrapped_approval_rules.all?(&:approved?)
    end
  end
  alias_method :any_approver_allowed?, :approved?

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
  # @param target [:approvers, :users]
  # @param unactioned [Boolean]
  def filtered_approvers(regular: true, code_owner: true, target: :approvers, unactioned: false)
    rules = []
    rules.concat(regular_rules) if regular
    rules.concat(code_owner_rules) if code_owner

    users = rules.flat_map(&target)
    users.uniq!

    users -= approved_approvers if unactioned

    self.class.filter_author(users, merge_request)
  end

  # approvers_left
  def unactioned_approvers
    strong_memoize(:unactioned_approvers) { approvers - approved_approvers }
  end

  def can_approve?(user)
    return false unless user
    # The check below considers authors being able to approve the MR.
    # That is, they're included/excluded from that list accordingly.
    return true if unactioned_approvers.include?(user)
    # We can safely unauthorize authors if it reaches this guard clause.
    return false if user == merge_request.author
    return false unless user.can?(:update_merge_request, merge_request)

    any_approver_allowed? && merge_request.approvals.where(user: user).empty?
  end

  def has_approved?(user)
    return false unless user

    approved_approvers.include?(user)
  end

  def authors_can_approve?
    project.merge_requests_author_approval?
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

  def regular_rules
    strong_memoize(:regular_rules) do
      rule_source = approval_rules_overwritten? ? merge_request : project
      rules = rule_source.approval_rules.regular

      unless project.feature_available?(:multiple_approval_rules)
        rules = rules.order(id: :asc).limit(1)
      end

      wrap_rules(rules)
    end
  end

  def code_owner_rules
    strong_memoize(:code_owner_rules) do
      wrap_rules(merge_request.approval_rules.code_owner)
    end
  end

  def wrap_rules(rules)
    rules.map { |rule| ApprovalWrappedRule.new(merge_request, rule) }
  end
end
