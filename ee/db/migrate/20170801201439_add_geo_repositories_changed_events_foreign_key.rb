class AddGeoRepositoriesChangedEventsForeignKey < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :geo_event_log, :geo_repositories_changed_events,
                               column: :repositories_changed_event_id, on_delete: :cascade
  end

  def down
    remove_foreign_key :geo_event_log, column: :repositories_changed_event_id
  end
end
