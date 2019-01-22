# frozen_string_literal: true

module ApprovalRules
  class UpdateService < ::ApprovalRules::BaseService
    attr_reader :rule

    def initialize(approval_rule, user, params)
      @rule = approval_rule
      super(@rule.project, user, params)
    end
  end
end
