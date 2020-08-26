# frozen_string_literal: true

module Groups::GroupMembersHelper
  include AvatarsHelper

  def group_member_select_options
    { multiple: true, class: 'input-clamp qa-member-select-field ', scope: :all, email_user: true }
  end

  def render_invite_member_for_group(group, default_access_level)
    render 'shared/members/invite_member', submit_url: group_group_members_path(group), access_levels: GroupMember.access_level_roles, default_access_level: default_access_level
  end

  def linked_groups_data_json(group_links)
    mapped_groups = group_links.map do |group_link|
      shared_with_group = group_link.shared_with_group

      data = {
        access_level: {
          integer_value: group_link.group_access
        }
      }

      if shared_with_group.present?
        data[:shared_with_group] = {
          id: shared_with_group.id,
          name: shared_with_group.full_name,
          avatar_url: shared_with_group.avatar_url(only_path: false),
          web_url: Gitlab::UrlBuilder.build(shared_with_group)
        }
      end

      data.deep_merge(shared_member_data(group_link))
    end

    mapped_groups.to_json
  end

  def members_data_json(group, members)
    members_data(group, members).to_json
  end

  private

  def shared_member_data(source)
    {
      id: source.id,
      created_at: source.created_at,
      expires_at: source.expires_at&.to_time,
      access_level: {
        string_value: source.human_access
      }
    }
  end

  def members_data(group, members)
    mapped_members = members.map do |member|
      user = member.user
      source = member.source

      data = {
        requested_at: member.requested_at,
        can_update: member.can_update?,
        can_remove: member.can_remove?,
        can_override: member.can_override?,
        access_level: {
          integer_value: member.access_level
        }
      }

      if source.present?
        data[:source] = {
          id: source.id,
          name: source.full_name,
          web_url: Gitlab::UrlBuilder.build(source)
        }
      end

      if user.present?
        data[:user] = {
          id: user.id,
          name: user.name,
          username: user.username,
          web_url: Gitlab::UrlBuilder.build(user),
          avatar_url: user.avatar_url,
          blocked: user.blocked?,
          two_factor_enabled: user.two_factor_enabled?
        }
      else
        data[:invite] = {
          email: member.invite_email,
          avatar_url: avatar_icon_for_email(member.invite_email, 40),
          can_resend: member.can_resend_invite?
        }
      end

      data.deep_merge(shared_member_data(member))
    end

    mapped_members
  end
end

Groups::GroupMembersHelper.prepend_if_ee('EE::Groups::GroupMembersHelper')
