# frozen_string_literal: true

class ApprovalMergeRequestRule < ApplicationRecord
  include Gitlab::Utils::StrongMemoize
  include ApprovalRuleLike

  scope :not_matching_pattern, -> (pattern) { code_owner.where.not(name: pattern) }
  scope :matching_pattern, -> (pattern) { code_owner.where(name: pattern) }

  validates :name, uniqueness: { scope: [:merge_request, :code_owner] }
  validates :report_type, presence: true, if: :report_approver?
  # Temporary validations until `code_owner` can be dropped in favor of `rule_type`
  # To be removed with https://gitlab.com/gitlab-org/gitlab-ee/issues/11834
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
    code_owner: 2,
    report_approver: 3
  }

  enum report_type: {
    security: 1
  }

  # Deprecated scope until code_owner column has been migrated to rule_type
  # To be removed with https://gitlab.com/gitlab-org/gitlab-ee/issues/11834
  scope :code_owner, -> { where(code_owner: true).or(where(rule_type: :code_owner)) }

  def self.find_or_create_code_owner_rule(merge_request, pattern)
    merge_request.approval_rules.code_owner.where(name: pattern).first_or_create do |rule|
      rule.rule_type = :code_owner
      rule.code_owner = true # deprecated, replaced with `rule_type: :code_owner`
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def project
    merge_request.target_project
  end

  # ApprovalRuleLike interface
  # Temporary override to handle legacy records that have not yet been migrated
  # To be removed with https://gitlab.com/gitlab-org/gitlab-ee/issues/11834
  def regular?
    read_attribute(:rule_type) == 'regular' || code_owner == false
  end
  alias_method :regular, :regular?

  # Temporary override to handle legacy records that have not yet been migrated
  # To be removed with https://gitlab.com/gitlab-org/gitlab-ee/issues/11834
  def code_owner?
    read_attribute(:rule_type) == 'code_owner' || code_owner
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

  private

  def validate_approvals_required
    return unless approval_project_rule
    return unless approvals_required_changed?

    if approvals_required < approval_project_rule.approvals_required
      errors.add(:approvals_required, :greater_than_or_equal_to, count: approval_project_rule.approvals_required)
    end
  end
end
