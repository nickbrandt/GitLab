# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddMarkForDeletionIndexesToProjects < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # To disable transactions uncomment the following line and remove these
  # comments:
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :projects, :users, column: :marked_for_deletion_by_id, on_delete: :nullify
    add_concurrent_index :projects, :marked_for_deletion_by_id, where: 'marked_for_deletion_by_id IS NOT NULL'
  end

  def down
    remove_foreign_key_if_exists :projects, column: :marked_for_deletion_by_id
    remove_concurrent_index :projects, :marked_for_deletion_by_id
  end
end
