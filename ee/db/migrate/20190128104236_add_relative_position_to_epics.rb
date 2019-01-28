# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRelativePositionToEpics < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    default_position = Gitlab::Database::MAX_INT_VALUE / 2
    add_column_with_default(:epics, :relative_position, :integer, default: default_position, allow_null: false)
  end

  def down
    remove_column :epics, :relative_position
  end
end
