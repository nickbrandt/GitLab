# frozen_string_literal: true

class AddUserDetailsMigrationIndexToUsers < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  INDEX_NAME = 'tmp_idx_on_user_id_user_details_sync'.freeze

  disable_ddl_transaction!

  def up
    add_concurrent_index :users, :id, where: Gitlab::BackgroundMigration::MigrateToUserDetails::USER_QUERY_CONDITION, name: INDEX_NAME
  end

  def down
    # no-op so BG migrations will still be performant in case of a rollback
  end
end
