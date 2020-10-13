# frozen_string_literal: true

class AddIndexToPackageEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_packages_events_on_created_and_types_and_originator'

  def up
    add_concurrent_index :packages_events, [:originator, :originator_type, :event_type, :created_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name(:packages_events, INDEX_NAME)
  end
end
