# frozen_string_literal: true

class CreateDependencyProxyGroupSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :dependency_proxy_group_settings do |t|
      t.references :group,
        references: :namespace,
        column: :group_id,
        index: true,
        null: false

      t.foreign_key :namespaces, column: :group_id, on_delete: :cascade

      t.timestamps_with_timezone null: false

      t.boolean :enabled, default: false, null: false
    end
  end
end
