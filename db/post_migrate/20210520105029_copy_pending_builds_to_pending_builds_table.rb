# frozen_string_literal: true

class CopyPendingBuildsToPendingBuildsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  BUILDS_MAX_SIZE = 1 << (32 - 1)
  PENDING_BUILDS_BATCH_SIZE = 1000
  PENDING_BUILDS_MAX_BATCHES = BUILDS_MAX_SIZE / PENDING_BUILDS_BATCH_SIZE

  disable_ddl_transaction!

  def up
    1.step do |i|
      inserts = execute <<~SQL
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
          LIMIT #{PENDING_BUILDS_BATCH_SIZE}
        ), inserts AS (
          INSERT INTO ci_pending_builds (build_id, project_id)
            SELECT id,
                   project_id
            FROM pending_builds
            ON CONFLICT DO NOTHING
            RETURNING id
        )
        SELECT COUNT(*) FROM inserts;
      SQL

      break if inserts.values.flatten.first.to_i == 0

      if i > PENDING_BUILDS_MAX_BATCHES
        raise 'There are too many pending builds in your database! Aborting.'
      end
    end
  end

  def down
    # noop
  end
end
