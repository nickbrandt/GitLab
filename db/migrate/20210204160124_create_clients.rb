# frozen_string_literal: true

class CreateClients < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      create_table :clients do |t|
        t.references :namespace, index: true, null: false, foreign_key: { on_delete: :cascade }

        t.timestamps_with_timezone
        t.text :name, null: false
        t.text :email, null: false, default: ''
        t.text :phone, null: false, default: ''
        t.text :description, null: false, default: '' # rubocop:disable Migration/AddLimitToTextColumns
        t.boolean :active, null: false, default: true

        t.index [:namespace_id, :name], unique: true
        t.index [:namespace_id, :email]
      end
    end

    add_text_limit(:clients, :name, 255)
    add_text_limit(:clients, :email, 255)
    add_text_limit(:clients, :phone, 50)
  end

  def down
    with_lock_retries do
      drop_table :clients
    end
  end
end
