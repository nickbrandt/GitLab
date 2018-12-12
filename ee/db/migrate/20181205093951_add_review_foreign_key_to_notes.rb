# frozen_string_literal: true

class AddReviewForeignKeyToNotes < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key(:notes, :reviews, column: :review_id, on_delete: :nullify)
    add_concurrent_index :notes, :review_id
  end

  def down
    remove_foreign_key :notes, column: :review_id
    remove_concurrent_index(:notes, :review_id)
  end
end
