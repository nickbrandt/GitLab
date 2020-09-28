# frozen_string_literal: true

class FixNotesVarcharLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_table :notes do |t| # rubocop:disable Migration/WithLockRetriesDisallowedMethod
        t.change :attachment, :text
        t.change :commit_id, :text
        t.change :line_code, :text
        t.change :noteable_type, :text
      end
    end
  end

  def down
    # no op
  end
end
