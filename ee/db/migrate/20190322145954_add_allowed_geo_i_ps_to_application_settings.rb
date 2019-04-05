# frozen_string_literal: true

class AddAllowedGeoIPsToApplicationSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :geo_node_allowed_ips, :string, default: '0.0.0.0/0, ::/0'
  end
end
