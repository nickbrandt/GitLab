# frozen_string_literal: true

class AddPendingDeleteToJobArtifactRegistry < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:job_artifact_registry,
                            :pending_delete,
                            :boolean,
                            default: false,
                            allow_null: false)
  end

  def down
    remove_column(:job_artifact_registry, :pending_delete)
  end
end
