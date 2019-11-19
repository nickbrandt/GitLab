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
      WITH RECURSIVE base_and_descendants AS
        (SELECT namespaces.id,
          namespaces.visibility_level, namespaces.parent_id, 0 AS parent_level
          FROM namespaces
          WHERE parent_id IS NOT NULL
          And type IN ('Group')
          UNION
          SELECT base_and_descendants.id,
          base_and_descendants.visibility_level, base_and_descendants.parent_id, namespaces.visibility_level AS parent_level
          FROM namespaces, base_and_descendants
          WHERE namespaces.type IN ('Group')
          AND namespaces.id = base_and_descendants.parent_id)
        SELECT id
        FROM base_and_descendants
        WHERE visibility_level > parent_level
      SQL
    group_ids = group_ids.column_values(0)

    return if group_ids.empty?

    execute("UPDATE namespaces
      SET visibility_level = parent.visibility_level
      FROM namespaces AS parent
      WHERE namespaces.parent_id = parent.id
      AND namespaces.id IN (#{group_ids.join(',')})")
  end
end
