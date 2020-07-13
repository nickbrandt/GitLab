# frozen_string_literal: true

class AddTargetIdToAuditEvent < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :audit_events, :target_id, :bigint
    end
  end

  def down
    with_lock_retries do
      remove_column :audit_events, :target_id
    end
  end
end
