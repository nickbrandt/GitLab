class AddGeoNodeVerificationStatus < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :geo_node_statuses, :repositories_verified_count, :integer
    add_column :geo_node_statuses, :repositories_verification_failed_count, :integer
    add_column :geo_node_statuses, :wikis_verified_count, :integer
    add_column :geo_node_statuses, :wikis_verification_failed_count, :integer
  end
end
