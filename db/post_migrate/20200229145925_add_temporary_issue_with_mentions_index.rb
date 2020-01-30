# frozen_string_literal: true

class AddTemporaryIssueWithMentionsIndex < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'issues_mentions_temp_index'

  INDEX_CONDITION = "description LIKE '%@%' OR title LIKE '%@%'"

  def up
    # create temporary index for notes with mentions, may take well over 1h
    add_concurrent_index(:issues, :id, where: INDEX_CONDITION, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index(:issues, :id, where: INDEX_CONDITION, name: INDEX_NAME)
  end
end
