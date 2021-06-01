# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ReplaceRunnersContactedAtIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  OLD_INDEX_NAME = 'index_ci_runners_on_contacted_at'
  NEW_INDEX_NAME = 'index_ci_runners_on_contacted_at_and_id'

  def up
    add_concurrent_index :ci_runners, [:contacted_at, :id], name: NEW_INDEX_NAME, using: 'btree'

    remove_concurrent_index_by_name :ci_runners, OLD_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :ci_runners, NEW_INDEX_NAME

    add_concurrent_index :ci_runners, :contacted_at, name: OLD_INDEX_NAME, using: 'btree'
  end
end
