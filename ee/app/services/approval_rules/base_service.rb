# frozen_string_literal: true

module ApprovalRules
  class BaseService < ::BaseService
    def execute
      return error(['Prohibited'], 403) unless can_edit?

      action
    end

    private

    def action
      raise 'Not implemented'
    end

    attr_reader :rule

    def can_edit?
      can?(current_user, :edit_approval_rule, rule)
    end

    def success(*args, &blk)
      super.tap { |hsh| hsh[:rule] = rule }
    end
  end
end
