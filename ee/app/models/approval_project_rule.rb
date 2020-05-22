# frozen_string_literal: true

class ApprovalProjectRule < ApplicationRecord
  include ApprovalRuleLike

  belongs_to :project
  has_and_belongs_to_many :protected_branches

  enum rule_type: {
    regular: 0,
    code_owner: 1, # currently unused
    report_approver: 2,
    any_approver: 3
  }

  alias_method :code_owner, :code_owner?
  validate :validate_default_license_report_name, on: :update, if: :report_approver?

  validates :name, uniqueness: { scope: [:project_id, :rule_type] }
  validates :rule_type, uniqueness: { scope: :project_id, message: proc { _('any-approver for the project already exists') } }, if: :any_approver?

  def self.applicable_to_branch(branch)
    includes(:protected_branches).select { |rule| rule.applies_to_branch?(branch) }
  end

  def self.inapplicable_to_branch(branch)
    includes(:protected_branches).reject { |rule| rule.applies_to_branch?(branch) }
  end

  def applies_to_branch?(branch)
    return true if protected_branches.empty?

    protected_branches.matching(branch).any?
  end

  def source_rule
    nil
  end

  def section
    nil
  end

  def apply_report_approver_rules_to(merge_request)
    report_type = report_type_for(self)
    rule = merge_request
      .approval_rules
      .report_approver
      .find_or_initialize_by(report_type: report_type)
    rule.update!(attributes_to_apply_for(report_type))
    rule
  end

  private

  def report_type_for(rule)
    ApprovalProjectRule::REPORT_TYPES_BY_DEFAULT_NAME[rule.name]
  end

  def attributes_to_apply_for(report_type)
    attributes
      .slice('approvals_required', 'name')
      .merge(
        users: users,
        groups: groups,
        approval_project_rule: self,
        rule_type: :report_approver,
        report_type: report_type
      )
  end

  def validate_default_license_report_name
    return unless name_changed?
    return unless name_was == ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT

    errors.add(:name, _("cannot be modified"))
  end
end
