# frozen_string_literal: true

class PrepareFileRegistryForSsf < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    change_column_default :file_registry, :retry_count, from: nil, to: 0
    add_column :file_registry, :state, :integer, null: false, limit: 2, default: 0
    add_column :file_registry, :last_synced_at, :datetime_with_timezone
    add_column :file_registry, :last_sync_failure, :text

    add_text_limit :file_registry, :last_sync_failure, 255
  end

  def down
    change_column_default :file_registry, :retry_count, from: 0, to: nil
    remove_column :file_registry, :state
    remove_column :file_registry, :last_synced_at
    remove_column :file_registry, :last_sync_failure
  end
end
