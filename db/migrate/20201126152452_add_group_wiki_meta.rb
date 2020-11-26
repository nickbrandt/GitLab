# frozen_string_literal: true

class AddGroupWikiMeta < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      unless table_exists?(:group_wiki_page_meta)
        create_table :group_wiki_page_meta, id: :serial do |t|
          t.references :group, index: true, foreign_key: { to_table: :namespaces, on_delete: :cascade }, null: false
          t.timestamps_with_timezone null: false
          t.text :title, null: false
        end
      end
    end

    add_text_limit :group_wiki_page_meta, :title, 255
  end

  def down
    with_lock_retries do
      drop_table :group_wiki_page_meta
    end
  end
end
