# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

# rubocop:disable RemoveIndex
class RemoveGeoNodeKeyIdIndex < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    remove_index(:geo_nodes, :geo_node_key_id)
  end
end
