# frozen_string_literal: true

class CopyPendingBuildsToPendingBuildsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # disable_ddl_transaction!

  def up
    with_lock_retries do
      execute <<~SQL
        WITH pending_builds AS (
          SELECT id,
                 project_id
          FROM ci_builds
          WHERE status = 'pending'
            AND type = 'Ci::Build'
            /* TODO queued_at */
          ORDER BY id
          LIMIT 1000
          FOR UPDATE
        )
        INSERT INTO ci_pending_builds (build_id, project_id)
          SELECT id,
                 project_id
          FROM pending_builds
          ON CONFLICT DO NOTHING;
      SQL
    end
  end

  def down
    # noop
  end
end
