# frozen_string_literal: true

class AddMinimumReverificationIntervalToGeoNodes < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default :geo_nodes, :minimum_reverification_interval, :integer, default: 7, allow_null: false
  end

  def down
    remove_column :geo_nodes, :minimum_reverification_interval
  end
end
