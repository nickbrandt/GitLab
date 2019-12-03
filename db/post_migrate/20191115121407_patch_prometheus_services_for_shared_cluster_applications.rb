# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PatchPrometheusServicesForSharedClusterApplications < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  MIGRATION = 'ActivatePrometheusServicesForSharedClusterApplications'.freeze
  BATCH_SIZE = 10_000

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    self.table_name = 'projects'

    include ::EachBatch
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(Project.where(pending_delete: false),
                                                          MIGRATION,
                                                          2.minutes,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end
end
