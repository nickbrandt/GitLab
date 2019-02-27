# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class SetDefaultPositionForChildEpics < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    current_position = nil
    current_parent_id = nil

    connection.exec_query(existing_child_epics_query.to_sql).rows.each do |id, parent_id|
      if parent_id != current_parent_id
        current_position = Gitlab::Database::MAX_INT_VALUE / 2
        current_parent_id = parent_id
      else
        current_position += 500
      end

      update_position(id, current_position)
    end
  end

  def down
  end

  private

  def epics_table
    @epics_table ||= Arel::Table.new(:epics)
  end

  def existing_child_epics_query
    epics_table.project(epics_table[:id], epics_table[:parent_id])
      .where(epics_table[:parent_id].not_eq(nil))
      .order(epics_table[:parent_id], epics_table[:id].desc)
  end

  def update_position(epic_id, position)
    execute "UPDATE epics SET relative_position = #{position} WHERE id = #{epic_id}"
  end
end
