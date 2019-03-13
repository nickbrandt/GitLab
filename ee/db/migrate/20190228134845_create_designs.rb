class CreateDesigns < ActiveRecord::Migration[5.0]
  def change
    create_table :design_management_designs, id: :bigserial do |t|
      t.references :project, foreign_key: { on_delete: :cascade }, index: true, null: false
      t.references :issue, foreign_key: { on_delete: :cascade }, index: { unique: true }, null: false

      t.string :filename, null: false
      t.index [:issue_id, :filename], unique: true
    end
  end
end
