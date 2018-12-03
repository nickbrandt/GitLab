class AddEpicsSortToUserPreference < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :user_preferences, :epics_sort, :string
  end
end
