# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddRunnersCreatedAtIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_runners_on_created_at_and_id'

  def up
    add_concurrent_index :ci_runners, [:created_at, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index :ci_runners, [:created_at, :id], name: INDEX_NAME
  end
end
