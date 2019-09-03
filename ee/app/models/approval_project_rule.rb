# frozen_string_literal: true

class ApprovalProjectRule < ApplicationRecord
  include ApprovalRuleLike

  belongs_to :project

  enum rule_type: {
    regular: 0,
    code_owner: 1, # currently unused
    report_approver: 2
  }

  alias_method :code_owner, :code_owner?

  def source_rule
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
end
