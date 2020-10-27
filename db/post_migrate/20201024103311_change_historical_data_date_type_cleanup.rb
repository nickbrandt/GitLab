# frozen_string_literal: true

class ChangeHistoricalDataDateTypeCleanup < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    cleanup_concurrent_column_type_change(:historical_data, :date)
  end

  def down
    undo_cleanup_concurrent_column_type_change(:historical_data, :date, :date)
  end
end
