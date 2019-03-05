class CreateDesignVersions < ActiveRecord::Migration[5.0]
  def change
    create_table :design_management_versions, id: :bigserial do |t|
      t.references :design_management_design, foreign_key: { on_delete: :cascade }, type: :bigint, null: false, index: true
      t.binary :sha, null: false, index: { unique: true }, limit: 20
    end
  end
end
