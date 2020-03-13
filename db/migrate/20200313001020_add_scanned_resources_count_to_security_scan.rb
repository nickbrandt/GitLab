# frozen_string_literal: true
class AddScannedResourcesCountToSecurityScan < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :security_scans, :scanned_resources_count, :integer, :null => false, :default => 0
  end
end
