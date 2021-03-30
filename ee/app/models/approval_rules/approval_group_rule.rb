# frozen_string_literal: true

module ApprovalRules
  class ApprovalGroupRule < ApplicationRecord
    include ApprovalRuleLike

    enum rule_type: {
      regular: 1,
      code_owner: 2,
      report_approver: 3,
      any_approver: 4
    }

    belongs_to :group, inverse_of: :approval_rules

    validates :group, presence: true
    validates :name, uniqueness: { scope: [:group_id, :rule_type] }
    validates :rule_type, uniqueness: {
      scope: :group_id,
      message: proc { _('any-approver for the group already exists') }
    }, if: :any_approver?
  end
end
