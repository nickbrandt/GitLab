# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveCyclicHierarchiesInEpics < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return unless Gitlab::Database.postgresql?

    epics_in_loops_sql = <<~SQL
      WITH RECURSIVE base_and_descendants (id, path, cycle) AS (
        SELECT epics.id, ARRAY[epics.id], false FROM epics WHERE epics.parent_id IS NOT NULL
      UNION
          SELECT epics.id, path || epics.id, epics.id = ANY(path)
          FROM epics, base_and_descendants
          WHERE epics.parent_id = base_and_descendants.id AND NOT cycle
      )
      SELECT id, array_to_string(path, ',') AS path FROM base_and_descendants WHERE cycle ORDER BY id
    SQL

    # Group by sorted path so we can group epics that belong to the same loop
    epics_grouped_by_loop = select_all(epics_in_loops_sql).group_by { |r| r['path'].split(',').uniq.sort.join(',') }

    # We only need to update the first epic of the loop to break the cycle
    epic_ids_to_update = epics_grouped_by_loop.map { |path, epics| epics.first['id'] }

    # rubocop:disable Lint/UnneededCopDisableDirective
    # rubocop:disable Migration/UpdateColumnInBatches
    update_column_in_batches(:epics, :parent_id, nil) do |table, query|
      query.where(
        table[:id].in(epic_ids_to_update)
      )
    end
  end

  def down
  end
end
