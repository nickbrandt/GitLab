# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddProjectCreationLevelToNamespaces < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    unless column_exists?(:namespaces, :project_creation_level)
      add_column :namespaces, :project_creation_level, :integer
    end
  end
end
