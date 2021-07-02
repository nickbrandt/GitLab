# frozen_string_literal: true

class CreateDastProfileSchedule < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      table_comment = {
        description: 'Stores DAST Profile schedules'
      }

      create_table :dast_profile_schedules, comment: table_comment.to_json do |t|
        t.bigint :dast_profile_id, null: false
        t.bigint :user_id, null: false
        t.boolean :active, default: true
        t.datetime_with_timezone :next_run_at
        t.timestamps_with_timezone null: false
        t.text :cron, null: false
      end
    end

    add_text_limit :dast_profile_schedules, :cron, 255

    add_index :dast_profile_schedules, :dast_profile_id
    add_index :dast_profile_schedules, :user_id
  end

  def down
    with_lock_retries do
      drop_table :dast_profile_schedules
    end
  end
end
