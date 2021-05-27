# frozen_string_literal: true

class CopyPendingBuildsToPendingBuildsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      execute <<~SQL
        WITH pending_builds AS (
          SELECT id,
                 project_id
          FROM ci_builds
          WHERE status = 'pending'
            AND type = 'Ci::Build'
            AND NOT EXISTS (
              SELECT 1 FROM ci_pending_builds
                WHERE ci_pending_builds.build_id = ci_builds.id
            )
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
