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

      create_table_with_constraints :dast_profile_schedules, comment: table_comment.to_json do |t|
        t.bigint :dast_profile_id, null: false
        t.bigint :user_id, null: false
        t.boolean :active, default: true
        t.datetime_with_timezone :next_run_at, null: false
        t.timestamps_with_timezone null: false

        t.index :dast_profile_id
        t.index :user_id

        t.text :cron, null: false
        t.text_limit :cron, 255
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :dast_profile_schedules
    end
  end
end
