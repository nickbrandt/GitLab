# frozen_string_literal: true

class FixProjectsWithoutProjectFeature < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  BATCH_SIZE = 50_000

  disable_ddl_transaction!

  class Project < ActiveRecord::Base
    include EachBatch
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(Project, 'FixProjectsWithoutProjectFeature', 2.minutes, batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end
end
