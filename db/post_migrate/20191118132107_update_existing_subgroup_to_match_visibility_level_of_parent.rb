# frozen_string_literal: true

class UpdateExistingSubgroupToMatchVisibilityLevelOfParent < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  class Namespace < ActiveRecord::Base
    self.table_name = 'namespaces'
  end

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_group_visibility_level
  end

  def down
    # no-op
  end

  def update_group_visibility_level
    group_ids = execute <<~SQL
      SELECT array_agg(id) as ids, min from (WITH RECURSIVE base_and_descendants AS (
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
        SELECT id, MIN(strictest_parent_level) as min
        FROM base_and_descendants
        WHERE visibility_level > strictest_parent_level
        GROUP BY id) as t1
      GROUP BY min
    SQL
    group_ids = group_ids.column_values(0)

    return if group_ids.empty?

  #   execute("UPDATE namespaces
  #     SET visibility_level = parent.visibility_level
  #     FROM namespaces AS parent
  #     WHERE namespaces.parent_id = parent.id
  #     AND namespaces.id IN (#{group_ids.join(',')})")
  # end
end
