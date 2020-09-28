# frozen_string_literal: true

class FixMergeRequestsVarcharLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_table :merge_requests do |t| # rubocop:disable Migration/WithLockRetriesDisallowedMethod
        t.change :merge_status, :text, default: 'unchecked'
        t.change :source_branch, :text
        t.change :target_branch, :text
        t.change :title, :text
      end
    end
  end

  def down
    # no op
  end
end
