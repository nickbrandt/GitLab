# frozen_string_literal: true

class PopulateProjectStatisticsPackagesSize < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    stats_ids = ProjectStatistics.joins(project: { packages: :package_files }).distinct.select(:id)

    packages_size = Arel.sql(
      '(SELECT SUM(size) FROM packages_package_files ' \
      'JOIN packages_packages ON packages_packages.id = packages_package_files.package_id ' \
      'WHERE packages_packages.project_id = project_statistics.project_id)'
    )
    update_column_in_batches(:project_statistics, :packages_size, packages_size) do |table, query|
      query.where(table[:id].in(stats_ids))
    end

    storage_size = Arel.sql('(repository_size + lfs_objects_size + build_artifacts_size + COALESCE(packages_size, 0))')
    update_column_in_batches(:project_statistics, :storage_size, storage_size) do |table, query|
      query.where(table[:id].in(stats_ids))
    end
  end

  def down
    storage_size = Arel.sql('(repository_size + lfs_objects_size + build_artifacts_size)')
    update_column_in_batches(:project_statistics, :storage_size, storage_size) do |table, query|
      query.where(table[:packages_size].gt(0))
    end

    update_column_in_batches(:project_statistics, :packages_size, nil)
  end
end
