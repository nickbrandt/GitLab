# frozen_string_literal: true

class CreateRequirements < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :requirements do |t|
      t.integer :state, limit: 2, default: 1, null: false
      t.integer :iid, null: false
      t.references :project, null: false, index: true, foreign_key: { on_delete: :cascade }
      t.references :author, index: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps_with_timezone null: false
      t.string :title, limit: 255, null: false
      t.text :title_html

      t.index :title
      t.index :state
      t.index :created_at
      t.index :updated_at
      t.index %w(project_id iid), name: 'index_requirements_on_project_id_and_iid', where: 'project_id IS NOT NULL', unique: true, using: :btree
    end
  end
end
