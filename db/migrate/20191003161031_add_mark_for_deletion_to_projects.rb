# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddMarkForDeletionToProjects < ActiveRecord::Migration[5.2]
  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :projects, :marked_for_deletion_at, :date
    add_column :projects, :marked_for_deletion_by_user_id, :integer
  end
end
