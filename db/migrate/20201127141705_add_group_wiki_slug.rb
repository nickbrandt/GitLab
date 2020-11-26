# frozen_string_literal: true

class AddGroupWikiSlug < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      unless table_exists?(:group_wiki_page_slugs)
        create_table :group_wiki_page_slugs, id: :serial do |t|
          t.boolean :canonical, default: false, null: false
          t.references :group_wiki_page_meta, index: true, foreign_key: { on_delete: :cascade }, null: false
          t.timestamps_with_timezone null: false
          t.text :slug, null: false
          t.index [:slug, :group_wiki_page_meta_id], unique: true
          t.index [:group_wiki_page_meta_id], name: 'one_canonical_group_wiki_page_slug_per_metadata', unique: true, where: "(canonical = true)"
        end
      end
    end

    add_text_limit :group_wiki_page_slugs, :slug, 2048
  end

  def down
    with_lock_retries do
      drop_table :group_wiki_page_slugs
    end
  end
end
