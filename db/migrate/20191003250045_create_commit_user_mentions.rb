# frozen_string_literal: true

class CreateCommitUserMentions < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :commit_user_mentions do |t|
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
      t.binary :commit_id, limit: 40, null: false
    end

    add_index :commit_user_mentions, :commit_id
  end
end
