# frozen_string_literal: true

class ValidateFileStoreNotNullConstraintCiJobArtifacts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  CONSTRAINT_NAME = 'ci_job_artifacts_file_store_not_null'
  DOWNTIME = false

  def up
    with_lock_retries do
      execute <<~SQL
        ALTER TABLE ci_job_artifacts VALIDATE CONSTRAINT #{CONSTRAINT_NAME};
      SQL
    end
  end

  def down
    # no-op
  end
end
