# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRelativePositionToEpics < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :epics, :relative_position, :integer
  end

  def down
    remove_column :epics, :relative_position
  end
end
