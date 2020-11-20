# frozen_string_literal: true

class DropIndexCiJobArtifactsOnJobIdAndFileType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  FILE_TYPE_EXCLUDED_FROM_UNIQUE_INDEX = [
    Ci::JobArtifact.file_types['archive'], 
    Ci::JobArtifact.file_types['metadata']
  ]
  WHERE_CLAUSE_FOR_UNIQUE_INDEX = FILE_TYPE_EXCLUDED_FROM_UNIQUE_INDEX.map do |file_type| 
    "file_type <> #{file_type}" 
  end.join(' AND ')

  def up
    remove_concurrent_index_by_name :ci_job_artifacts, 'index_ci_job_artifacts_on_job_id_and_file_type'
    add_concurrent_index :ci_job_artifacts, ["job_id", "file_type"], 
      { 
        unique: true, 
        name: 'index_ci_job_artifacts_on_job_id_and_file_type', 
        where: WHERE_CLAUSE_FOR_UNIQUE_INDEX
      }
  end

  def down
    # no-op
  end
end
