class CreateFileRegistry < ActiveRecord::Migration[4.2]
  def change
    create_table :file_registry do |t|
      t.string  :file_type, null: false # rubocop:disable Migration/AddLimitToStringColumns
      t.integer :file_id, null: false
      t.integer :bytes
      t.string  :sha256 # rubocop:disable Migration/AddLimitToStringColumns

      t.datetime :created_at, null: false
    end

    add_index :file_registry, :file_type
    add_index :file_registry, [:file_type, :file_id], { unique: true }
  end
end
