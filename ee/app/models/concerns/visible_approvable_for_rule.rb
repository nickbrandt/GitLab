# frozen_string_literal: true

# This module may only be used by presenters or modules
# that include the Approvable concern
module VisibleApprovableForRule
  def approvers_left
    return super unless ::Feature.enabled_approval_rule?

    approval_state.unactioned_approvers
  end

  def overall_approvers(exclude_code_owners: false)
    return super unless ::Feature.enabled_approval_rule?

    options = { target: :users }
    options[:code_owner] = false if exclude_code_owners

    approvers = approval_state.filtered_approvers(options)
    approvers.uniq!
    approvers
  end

  def all_approvers_including_groups
    return super unless ::Feature.enabled_approval_rule?

    approval_state.approvers
  end

  def approvers_from_groups
    return super unless ::Feature.enabled_approval_rule?

    groups = approval_state.wrapped_approval_rules.flat_map(&:groups)
    User.joins(:group_members).where(members: { source_id: groups })
  end
end
