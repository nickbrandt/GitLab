# frozen_string_literal: true

class CreateWorkItemTypes < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    with_lock_retries do
      create_table_with_constraints :work_item_types do |t|
        t.integer :kind, limit: 2, default: 0, null: false
        t.integer :cached_markdown_version
        t.text :name, null: false
        t.text :description # rubocop:disable Migration/AddLimitToTextColumns
        t.text :description_html # rubocop:disable Migration/AddLimitToTextColumns
        t.text :icon_name, null: true
        t.references :namespace, foreign_key: { on_delete: :cascade }, index: true, null: true
        t.timestamps_with_timezone null: false

        t.index :kind

        t.text_limit :name, 255
        t.text_limit :icon_name, 255
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :work_item_types
    end
  end
end
