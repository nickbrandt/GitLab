# rubocop:disable Migration/Datetime
class AddSharedRunnersSecondsToProjectStatistics < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    counter_column = { limit: 8, null: false, default: 0 }
    add_column :project_statistics, :shared_runners_seconds, :integer, counter_column
    add_column :project_statistics, :shared_runners_seconds_last_reset, :timestamp
  end
end
