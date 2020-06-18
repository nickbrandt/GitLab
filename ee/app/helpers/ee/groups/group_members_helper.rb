# frozen_string_literal: true

module EE::Groups::GroupMembersHelper
  extend ::Gitlab::Utils::Override

  override :group_member_select_options
  def group_member_select_options
    super.merge(skip_ldap: @group.ldap_synced?)
  end

  override :access_level_roles
  def access_level_roles(group)
    levels = GroupMember.access_level_roles
    return levels if group.unassigned_role_allowed?

    levels.except("Unassigned")
  end
end
