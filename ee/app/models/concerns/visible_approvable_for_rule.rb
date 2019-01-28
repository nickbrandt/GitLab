# frozen_string_literal: true

# This module may only be used by presenters or modules
# that include the Approvable concern
module VisibleApprovableForRule
  def approvers_left
    return super if approval_rules_disabled?

    approval_state.unactioned_approvers
  end

  def overall_approvers(exclude_code_owners: false)
    return super if approval_rules_disabled?

    options = { target: :users }
    options[:code_owner] = false if exclude_code_owners

    approvers = approval_state.filtered_approvers(options)
    approvers.uniq!
    approvers
  end

  def all_approvers_including_groups
    return super if approval_rules_disabled?

    approval_state.approvers
  end

  def approvers_from_groups
    return super if approval_rules_disabled?

    groups = approval_state.wrapped_approval_rules.flat_map(&:groups)
    User.joins(:group_members).where(members: { source_id: groups })
  end

  def approval_rules_disabled?
    ::Feature.disabled?(:approval_rules, project)
  end
end
