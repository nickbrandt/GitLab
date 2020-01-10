# frozen_string_literal: true

class AddIdToDesignManagementDesignsVersions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :design_management_designs_versions, :id, :primary_key
  end
end
