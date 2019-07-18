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
end
