# frozen_string_literal: true

class ApprovalMergeRequestRule < ApplicationRecord
  include Gitlab::Utils::StrongMemoize
  include ApprovalRuleLike

  DEFAULT_NAME_FOR_CODE_OWNER = 'Code Owner'

  scope :not_matching_pattern, -> (pattern) { code_owner.where.not(name: pattern) }
  scope :matching_pattern, -> (pattern) { code_owner.where(name: pattern) }
  # Deprecated scope until code_owner column has been migrated to rule_type
  scope :code_owner, -> { where(code_owner: true).or(rule_type: :code_owner) }

  validates :name, uniqueness: { scope: [:merge_request, :code_owner] }
  # Temporary validations until `code_owner` can be dropped in favor of `rule_type`
  validates :code_owner, inclusion: { in: [true], if: :code_owner? }
  validates :code_owner, inclusion: { in: [false], if: :regular? }

  belongs_to :merge_request, inverse_of: :approval_rules

  # approved_approvers is only populated after MR is merged
  has_and_belongs_to_many :approved_approvers, class_name: 'User', join_table: :approval_merge_request_rules_approved_approvers
  has_one :approval_merge_request_rule_source
  has_one :approval_project_rule, through: :approval_merge_request_rule_source
  alias_method :source_rule, :approval_project_rule

  validate :validate_approvals_required

  enum rule_type: {
    regular: 1,
    code_owner: 2
  }

  def self.find_or_create_code_owner_rule(merge_request, pattern)
    merge_request.approval_rules.safe_find_or_create_by(
      rule_type: :code_owner,
      code_owner: true, # deprecated, replaced with `rule_type: :code_owner`
      name: pattern
    )
  end

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
    strong_memoize(:approvers) do
      scope_or_array = super

      next scope_or_array unless merge_request.author
      next scope_or_array if project.merge_requests_author_approval?

      if scope_or_array.respond_to?(:where)
        scope_or_array.where.not(id: merge_request.author)
      else
        scope_or_array - [merge_request.author]
      end
    end
  end

  def sync_approved_approvers
    # Before being merged, approved_approvers are dynamically calculated in ApprovalWrappedRule instead of being persisted.
    return unless merge_request.merged?

    self.approved_approver_ids = merge_request.approvals.map(&:user_id) & approvers.map(&:id)
  end

  # ApprovalRuleLike interface
  alias_method :regular, :regular?

  private

  def validate_approvals_required
    return unless approval_project_rule
    return unless approvals_required_changed?

    if approvals_required < approval_project_rule.approvals_required
      errors.add(:approvals_required, :greater_than_or_equal_to, count: approval_project_rule.approvals_required)
    end
  end
end
