# frozen_string_literal: true

class CreateDependencyProxyBlobs < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :dependency_proxy_blobs do |t|
      t.references :group,
        references: :namespace,
        column: :group_id,
        index: false,
        null: false

      t.foreign_key :namespaces, column: :group_id, on_delete: :cascade

      t.timestamps_with_timezone null: false

      t.bigint :size
      t.integer :file_store
      t.string :file_name, null: false
      t.text :file, null: false

      t.index [:group_id, :file_name]
    end
  end
end
