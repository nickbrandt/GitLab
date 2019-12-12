# frozen_string_literal: true

class UpdateExistingSubgroupToMatchVisibilityLevelOfParent < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  VISIBILITY_LEVELS = {
    private: 0,
    internal: 10
  }

  def up
    update_namespaces_with_level(VISIBILITY_LEVELS[:private])
    update_namespaces_with_level(VISIBILITY_LEVELS[:internal])
  end

  def update_namespaces_with_level(visibility_level)
    namespace_ids_with_level(visibility_level).rows.each_slice(500) do |ids|
      execute <<~SQL
        UPDATE namespaces
        SET visibility_level = #{visibility_level}
        WHERE namespaces.id IN (#{ids.join(',')})
      SQL
    end
  end

  def namespace_ids_with_level(visibility_level)
    exec_query <<~SQL
      SELECT id
      FROM (
        WITH RECURSIVE base_and_descendants AS (
          (SELECT visibility_level AS strictest_parent_level,
                  namespaces.*
           FROM namespaces
           WHERE namespaces.type IN ('Group'))
        UNION
          (SELECT LEAST(namespaces.visibility_level, base_and_descendants.strictest_parent_level) AS strictest_parent_level,
                  namespaces.*
           FROM namespaces,
                base_and_descendants
           WHERE namespaces.type IN ('Group')
             AND namespaces.parent_id = base_and_descendants.id))
        SELECT id, MIN(strictest_parent_level) AS strictest_parent_level
        FROM base_and_descendants
        WHERE visibility_level > strictest_parent_level
        GROUP BY id) as namespaces_levels
      WHERE strictest_parent_level = #{visibility_level}
    SQL
  end

  def down
    # no-op
  end
end
