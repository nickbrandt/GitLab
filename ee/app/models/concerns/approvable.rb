module Approvable
  # A method related to approvers that is user facing
  # should be moved to VisibleApprovable because
  # of the fact that we use filtered versions of certain methods
  # such as approver_groups and target_project in presenters
  include ::VisibleApprovable

  def approval_needed?
    approvals_required&.nonzero?
  end

  def approved?
    approvals_left < 1
  end

  # Number of approvals remaining (excluding existing approvals) before the MR is
  # considered approved. If there are fewer potential approvers than approvals left,
  # choose the lower so the MR doesn't get 'stuck' in a state where it can't be approved.
  #
  def approvals_left
    [
      [approvals_required - approvals.size, number_of_potential_approvers].min,
      0
    ].max
  end

  def approvals_required
    approvals_before_merge || target_project.approvals_before_merge
  end

  def approvals_before_merge
    return nil unless project&.feature_available?(:merge_request_approvers)

    super
  end

  # An MR can potentially be approved by:
  # - anyone in the approvers list
  # - any other project member with developer access or higher (if there are no approvers
  #   left)
  #
  # It cannot be approved by:
  # - a user who has already approved the MR
  # - the MR author
  #
  def number_of_potential_approvers
    has_access = ['access_level > ?', Member::REPORTER]
    users_with_access = { id: project.project_authorizations.where(has_access).select(:user_id) }
    all_approvers = all_approvers_including_groups

    users_relation = User.active.where.not(id: approvals.select(:user_id))
    users_relation = users_relation.where.not(id: author.id) if author

    # This is an optimisation for large instances. Instead of getting the
    # count of all users who meet the conditions in a single query, which
    # produces a slow query plan, we get the union of all users with access
    # and all users in the approvers list, and count them.
    if all_approvers.any?
      specific_approvers = { id: all_approvers.map(&:id) }

      union = Gitlab::SQL::Union.new([
        users_relation.where(users_with_access).select(:id),
        users_relation.where(specific_approvers).select(:id)
      ])

      User.from("(#{union.to_sql}) subquery").count
    else
      users_relation.where(users_with_access).count
    end
  end

  # Even though this method is used in VisibleApprovable
  # we do not want to encounter a scenario where there are
  # no user approvers but there is one merge request group
  # approver that is not visible to the current_user,
  # which would make this method return false
  # when it should still report as overwritten.
  # To prevent this from happening, approvers_overwritten?
  # makes use of the unfiltered version of approver_groups so that
  # it always takes into account every approver
  # available
  #
  def approvers_overwritten?
    approvers.to_a.any? || approver_groups.to_a.any?
  end

  def can_approve?(user)
    return false unless user
    return true if approvers_left.include?(user)
    return false if user == author
    return false unless user.can?(:update_merge_request, self)

    any_approver_allowed? && approvals.where(user: user).empty?
  end

  def has_approved?(user)
    return false unless user

    approved_by_users.include?(user)
  end

  # Once there are fewer approvers left in the list than approvals required or
  # there are no more approvals required
  # allow other project members to approve the MR.
  #
  def any_approver_allowed?
    remaining_approvals = approvals_left

    remaining_approvals.zero? || remaining_approvals > approvers_left.count
  end

  def approver_ids=(value)
    ::Gitlab::Utils.ensure_array_from_string(value).each do |user_id|
      next if author && user_id == author.id

      approvers.find_or_initialize_by(user_id: user_id, target_id: id)
    end
  end

  def approver_group_ids=(value)
    ::Gitlab::Utils.ensure_array_from_string(value).each do |group_id|
      approver_groups.find_or_initialize_by(group_id: group_id, target_id: id)
    end
  end
end
