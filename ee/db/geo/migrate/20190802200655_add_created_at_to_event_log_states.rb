# frozen_string_literal: true

class AddCreatedAtToEventLogStates < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    add_column(:event_log_states, :created_at, :datetime, null: true) # rubocop:disable Migration/Datetime

    # There should only be 1 record in the event_log_states table
    execute('UPDATE event_log_states SET created_at = (
      SELECT COALESCE(
        (SELECT project_registry.created_at
         FROM project_registry
         ORDER BY project_registry.id ASC
         LIMIT 1), NOW()
      )
    )')

    change_column_null(:event_log_states, :created_at, false)
  end

  def down
    remove_column(:event_log_states, :created_at)
  end
end
