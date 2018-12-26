# frozen_string_literal: true
# rubocop:disable Migration/UpdateColumnInBatches
class UpdatePackageType < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    update_column_in_batches(:packages_packages, :package_type, 1) do |table, query|
      query.where(table[:package_type].eq(nil))
    end

    change_column_null(:packages_packages, :package_type, false)
  end

  def down
    change_column_null(:packages_packages, :package_type, true)
  end
end
