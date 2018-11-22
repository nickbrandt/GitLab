class AddProjectCreationLevelToGroups < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :namespaces, :project_creation_level, :integer
  end
end
