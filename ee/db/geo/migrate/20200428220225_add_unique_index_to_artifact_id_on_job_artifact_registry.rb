# frozen_string_literal: true

class AddUniqueIndexToArtifactIdOnJobArtifactRegistry < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index(:job_artifact_registry, :artifact_id)
    add_concurrent_index(:job_artifact_registry, :artifact_id, unique: true)
  end

  def down
    remove_concurrent_index(:job_artifact_registry, :artifact_id)
    add_concurrent_index(:job_artifact_registry, :artifact_id)
  end
end
