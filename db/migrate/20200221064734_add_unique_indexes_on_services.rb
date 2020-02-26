# frozen_string_literal: true

class AddUniqueIndexesOnServices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # This query deletes services of the same type and on the same project
    # It excludes the services with the lowest IDs. Those are the services that are
    # actually in use. The ones that get deleted are not in use and will not be visible in the UI or API.
    execute <<~SQL
      DELETE FROM services
      WHERE project_id IS NOT NULL
      AND id NOT IN (
        SELECT MIN(id)
        FROM services
        WHERE project_id IS NOT NULL
        GROUP BY type, project_id
      );
    SQL

    add_concurrent_index :services, [:type, :project_id], unique: true, where: 'project_id IS NOT NULL'
  end

  def down
    remove_concurrent_index :services, [:type, :project_id]
  end
end
