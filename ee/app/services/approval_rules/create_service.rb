# frozen_string_literal: true

module ApprovalRules
  class CreateService < ::ApprovalRules::BaseService
    # @param target [Project, MergeRequest]
    def initialize(target, user, params)
      @rule = target.approval_rules.build
      super(@rule.project, user, params)
    end
  end
end
