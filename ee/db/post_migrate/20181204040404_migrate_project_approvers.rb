# frozen_string_literal: true

class MigrateProjectApprovers < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 1000

  class Project < ActiveRecord::Base
    include ::EachBatch
    self.table_name = 'projects'
  end

  def up
    jobs = []
    Project.each_batch(of: BATCH_SIZE) do |scope, _|
      jobs << ['MigrateApproverToApprovalRulesInBatch', ['Project', scope.pluck(:id)]]
    end
    BackgroundMigration.bulk_perform_async(jobs)
  end

  def down
  end
end
