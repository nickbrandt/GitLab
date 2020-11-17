# frozen_string_literal: true

class DropIndexCiJobArtifactsOnJobIdAndFileType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name :ci_job_artifacts, 'index_ci_job_artifacts_on_job_id_and_file_type'
  end

  def down
    # no-op
  end
end
