# frozen_string_literal: true

module EE::GroupMembersFinder
  extend ActiveSupport::Concern
  extend ::Gitlab::Utils::Override

  prepended do
    attr_reader :group
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def not_managed
    group.group_members.non_owners.joins(:user).merge(User.not_managed(group: group))
  end
  # rubocop: enable CodeReuse/ActiveRecord

  override :group_members_list
  def group_members_list
    return group.all_group_members if group.minimal_access_role_allowed?

    group.members
  end

  override :relation_group_members
  # rubocop: disable CodeReuse/ActiveRecord
  def relation_group_members(relation)
    members = ::GroupMember.non_request
      .where(source_id: relation.select(:id))
      .where.not(user_id: group.users.select(:id))

    return members if group.minimal_access_role_allowed?

    members.non_minimal_access
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
