# frozen_string_literal: true

module ApprovableForRule
  include VisibleApprovableForRule

  FORWARDABLE_METHODS = %w{
    approval_needed?
    approved?
    approvals_left
    can_approve?
    has_approved?
    any_approver_allowed?
    authors_can_approve?
    approvers_overwritten?
  }.freeze

  FORWARDABLE_METHODS.each do |method|
    define_method(method) do |*args|
      return super(*args) if approval_rules_disabled?

      approval_state.public_send(method, *args) # rubocop:disable GitlabSecurity/PublicSend
    end
  end
end
