# frozen_string_literal: true

class AddHideMembersFromOutsideGroupToNamespaceSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :namespace_settings, :hide_members_from_outside_group, :boolean, default: false, null: false
  end
end
