# frozen_string_literal: true

class CleanUpPendingBuildsTable < ActiveRecord::Migration[6.0]
  def up
    execute <<~SQL
      DELETE FROM ci_pending_builds
        USING ci_builds
        WHERE ci_builds.id = ci_pending_builds.build_id
          AND ci_builds.status != 'pending'
          AND ci_builds.type = 'Ci::Build'
    SQL
  end

  def down
    # noop
  end
end
