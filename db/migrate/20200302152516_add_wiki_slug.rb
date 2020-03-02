# frozen_string_literal: true

class AddWikiSlug < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    create_table :wiki_page_meta, id: :serial do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.string :title, null: false, limit: 255
    end

    create_table :wiki_page_slugs, id: :serial do |t|
      t.boolean :canonical, default: false, null: false
      t.references :wiki_page_meta, index: true, foreign_key: { on_delete: :cascade }, null: false
      t.string :slug, null: false, limit: 2048
      t.index [:slug, :wiki_page_meta_id], unique: true
    end
  end
end
