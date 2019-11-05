# frozen_string_literal: true

class CreateLfsObjectRegistry < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :lfs_object_registry, force: :cascade do |t|
      t.datetime_with_timezone :created_at
      t.datetime_with_timezone :retry_at
      t.integer :bytes, limit: 8
      t.integer :lfs_object_id
      t.integer :retry_count
      t.boolean :missing_on_primary, default: false, null: false
      t.boolean :success, default: false, null: false
      t.binary :sha256

      t.index :lfs_object_id, unique: true
      t.index :retry_at
      t.index :success
    end
  end
end
