# frozen_string_literal: true

class FixCiPipelinesVarcharLimits < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      change_table :ci_pipelines do |t| # rubocop:disable Migration/WithLockRetriesDisallowedMethod
        t.change :before_sha, :text
        t.change :ref, :text
        t.change :sha, :text
      end
    end
  end

  def down
    # no op
  end
end
