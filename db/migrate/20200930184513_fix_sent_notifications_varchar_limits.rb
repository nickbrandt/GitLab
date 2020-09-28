# frozen_string_literal: true

class FixSentNotificationsVarcharLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_table :sent_notifications do |t| # rubocop:disable Migration/WithLockRetriesDisallowedMethod
        t.change :commit_id, :text
        t.change :line_code, :text
        t.change :noteable_type, :text
        t.change :reply_key, :text
      end
    end
  end

  def down
    # no op
  end
end
