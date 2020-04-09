# frozen_string_literal: true

class AddUniquenessIndexToLabelTitleAndProject < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  PROJECT_AND_TITLE = [:project_id, :title]

  def up
    remove_concurrent_index :labels, PROJECT_AND_TITLE if index_exists? :labels, PROJECT_AND_TITLE
    add_concurrent_index :labels, PROJECT_AND_TITLE, where: "labels.group_id = null", unique: true
  end

  def down
    remove_concurrent_index :labels, PROJECT_AND_TITLE if index_exists? :labels, PROJECT_AND_TITLE
    add_concurrent_index :labels, PROJECT_AND_TITLE, where: "labels.group_id = null", unique: false
  end
end
