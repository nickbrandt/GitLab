# frozen_string_literal: true

class FixMergeRequestDiffsVarcharLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_column :merge_request_diffs, :state, :text # rubocop:disable Migration/WithLockRetriesDisallowedMethod
    end
  end

  def down
    # no op
  end
end
