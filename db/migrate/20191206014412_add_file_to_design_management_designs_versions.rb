# frozen_string_literal: true

class AddFileToDesignManagementDesignsVersions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :design_management_designs_versions, :file, :string, limit: 255
  end
end
