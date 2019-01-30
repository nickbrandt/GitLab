# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRoadmapSortToUserPreferences < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :user_preferences, :roadmaps_sort, :string, null: true
  end

  def down
    remove_column :user_preferences, :roadmaps_sort
  end
end
