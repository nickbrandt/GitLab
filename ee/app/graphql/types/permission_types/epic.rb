# frozen_string_literal: true

module Types
  module PermissionTypes
    class Epic < BasePermissionType
      description 'Check permissions for the current user on an epic'
      graphql_name 'EpicPermissions'

      abilities :read_epic, :read_epic_iid, :update_epic, :destroy_epic, :admin_epic,
                :create_epic, :create_note, :award_emoji
    end
  end
end
