class AddPushMirrorAllowedGroupIdToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :push_mirror_allowed_group_id, :integer
  end
end
