# frozen_string_literal: true

class AddDesignManagementDesignsVersions < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    create_table(:design_management_designs_versions, id: false) do |t|
      t.references :design,
                   null: false,
                   type: :bigint,
                   foreign_key: {
                     on_delete: :cascade,
                     to_table: :design_management_designs
                   }
      t.references :version,
                   null: false,
                   type: :bigint,
                   foreign_key: {
                     on_delete: :cascade,
                     to_table: :design_management_versions
                   }
    end

    add_index :design_management_designs_versions,
              [:design_id, :version_id],
              unique: true, name: "design_management_designs_versions_uniqueness"
  end
end
