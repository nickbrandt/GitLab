# frozen_string_literal: true

class CreateReviews < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def up
    create_table :reviews, id: :bigserial do |t|
      t.references :author, index: true, references: :users
      t.references :merge_request, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.references :project, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.datetime_with_timezone :created_at, null: false
    end

    add_foreign_key :reviews, :users, column: :author_id, on_delete: :nullify # rubocop:disable Migration/AddConcurrentForeignKey
  end

  def down
    remove_foreign_key :reviews, column: :author_id

    drop_table :reviews
  end
end
