# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddForeignKeyOnCiJobArtifactsJobId < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_ci_job_artifacts_on_job_id'

  def up
    unless index_exists?(:ci_job_artifacts, :job_id, name: INDEX_NAME)
      add_concurrent_index :ci_job_artifacts, :job_id, name: INDEX_NAME
    end
  end

  def down
    if index_exists?(:ci_job_artifacts, :job_id, name: INDEX_NAME)
      remove_concurrent_index :ci_job_artifacts, :job_id, name: INDEX_NAME
    end
  end
end
