# frozen_string_literal: true

class AddTargetTypeToAuditEvent < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :audit_events, :target_type, :text
    end
    add_text_limit(:audit_events, :target_type, 255)
  end

  def down
    remove_column(:audit_events, :target_type)
  end
end
