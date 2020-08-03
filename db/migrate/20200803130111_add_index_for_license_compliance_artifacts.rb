# frozen_string_literal: true

class AddIndexForLicenseComplianceArtifacts < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_job_artifacts, :file_type, where: 'file_type IN (10, 101)'
  end

  def down
    remove_concurrent_index :ci_job_artifacts, :file_type, where: 'file_type IN (10, 101)'
  end
end
