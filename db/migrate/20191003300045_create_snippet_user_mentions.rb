# frozen_string_literal: true

class CreateSnippetUserMentions < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :snippet_user_mentions do |t|
      t.references :snippet, type: :integer,
                   index: { where: 'snippet_id IS NOT NULL' }, null: false, foreign_key: { on_delete: :cascade }
      t.references :note, type: :integer,
                   index: { where: 'note_id IS NOT NULL' }, null: true, foreign_key: { on_delete: :cascade }
      t.references :mentioned_user, type: :integer,
                   index: { where: 'mentioned_user_id IS NOT NULL' }, null: true,
                   foreign_key: { to_table: :users, on_delete: :cascade }
      t.references :mentioned_project, type: :integer,
                   index: { where: 'mentioned_project_id IS NOT NULL' }, null: true,
                   foreign_key: { to_table: :projects, on_delete: :cascade }
      t.references :mentioned_group, references: :namespace,
                   type: :integer,
                   null: true,
                   index: { where: 'mentioned_group_id IS NOT NULL' },
                   foreign_key: { to_table: :namespaces, column: :group_id, on_delete: :cascade }
    end
  end
end
