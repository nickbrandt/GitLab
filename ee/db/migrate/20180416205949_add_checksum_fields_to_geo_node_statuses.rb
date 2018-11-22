class AddChecksumFieldsToGeoNodeStatuses < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :geo_node_statuses, :repositories_checksummed_count, :integer
    add_column :geo_node_statuses, :repositories_checksum_failed_count, :integer
    add_column :geo_node_statuses, :repositories_checksum_mismatch_count, :integer
    add_column :geo_node_statuses, :wikis_checksummed_count, :integer
    add_column :geo_node_statuses, :wikis_checksum_failed_count, :integer
    add_column :geo_node_statuses, :wikis_checksum_mismatch_count, :integer
  end
end
