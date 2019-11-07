# frozen_string_literal: true

class AddIndexToProjectsOnMarkedForDeletion < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def change
    add_concurrent_index :projects, :marked_for_deletion_at, where: 'marked_for_deletion_at IS NOT NULL'
  end
end
