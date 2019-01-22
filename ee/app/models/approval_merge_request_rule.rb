# frozen_string_literal: true

class ApprovalMergeRequestRule < ApplicationRecord
  include ApprovalRuleLike

  DEFAULT_NAME_FOR_CODE_OWNER = 'Code Owner'

  scope :regular, -> { where(code_owner: false) }
  scope :code_owner, -> { where(code_owner: true) } # special code owner rules, updated internally when code changes

  belongs_to :merge_request

  # approved_approvers is only populated after MR is merged
  has_and_belongs_to_many :approved_approvers, class_name: 'User', join_table: :approval_merge_request_rules_approved_approvers
  has_one :approval_merge_request_rule_source
  has_one :approval_project_rule, through: :approval_merge_request_rule_source

  validate :validate_approvals_required

  def project
    merge_request.target_project
  end

  def approval_project_rule_id=(approval_project_rule_id)
    self.approval_merge_request_rule_source ||= build_approval_merge_request_rule_source
    self.approval_merge_request_rule_source.approval_project_rule_id = approval_project_rule_id
  end

  # Users who are eligible to approve, including specified group members.
  # Excludes the author if 'self-approval' isn't explicitly
  # enabled on project settings.
  # @return [Array<User>]
  def approvers
    scope = super

    if merge_request.author && !project.merge_requests_author_approval?
      scope = scope.where.not(id: merge_request.author)
    end

    scope
  end

  def sync_approved_approvers
    # Before being merged, approved_approvers are dynamically calculated in ApprovalWrappedRule instead of being persisted.
    return unless merge_request.merged?

    self.approved_approver_ids = merge_request.approvals.map(&:user_id) & approvers.map(&:id)
  end

  private

  def validate_approvals_required
    return unless approval_project_rule
    return unless approvals_required_changed?

    if approvals_required < approval_project_rule.approvals_required
      errors.add(:approvals_required, :greater_than_or_equal_to, count: approval_project_rule.approvals_required)
    end
  end
end
