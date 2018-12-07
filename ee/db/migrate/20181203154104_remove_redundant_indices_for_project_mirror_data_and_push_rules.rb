# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveRedundantIndicesForProjectMirrorDataAndPushRules < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index(*index_on_project_mirror_data)
    remove_concurrent_index(*index_on_push_rules)
  end

  def down
    add_concurrent_index(*index_on_push_rules)
    add_concurrent_index(*index_on_project_mirror_data)
  end

  private

  def index_on_project_mirror_data
    [
      :project_mirror_data,
      [:next_execution_timestamp],
      { name: 'index_project_mirror_data_on_next_execution_timestamp' }
    ]
  end

  def index_on_push_rules
    [
      :push_rules,
      [:is_sample],
      { name: 'index_push_rules_is_sample' }
    ]
  end
end
