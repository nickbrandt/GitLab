# frozen_string_literal: true

class AddIndexWithActiveRunnableSchedulesToDastProfileSchedules < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  INDEX_NAME = 'index_dast_profile_schedules_active_next_run_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index :dast_profile_schedules, [:active, :next_run_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :dast_profile_schedules, INDEX_NAME
  end
end
