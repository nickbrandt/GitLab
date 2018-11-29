class AddSharedRunnersMinutesToApplicationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :shared_runners_minutes, :integer, null: false, default: 0
  end
end
