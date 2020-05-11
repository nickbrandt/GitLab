class CreateGroupFeatures < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :namespace_features do |t|
      t.references :namespace, foreign_key: { on_delete: :cascade }, index: { unique: true }, null: false
      t.integer :wiki_access_level, null: false
    end
  end
end
