# frozen_string_literal: true

class FixTaggingsVarcharLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_table :taggings do |t| # rubocop:disable Migration/WithLockRetriesDisallowedMethod
        t.change :context, :text
        t.change :taggable_type, :text
        t.change :tagger_type, :text
      end
    end
  end

  def down
    # no op
  end
end
