class AddGeoNodesVerificationMaxCapacity < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    # rubocop:disable Migration/AddColumn
    add_column :geo_nodes, :verification_max_capacity, :integer, default: 100, null: false
  end
end
