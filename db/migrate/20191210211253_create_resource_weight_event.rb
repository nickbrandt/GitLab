# frozen_string_literal: true

class CreateResourceWeightEvent < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :resource_weight_events do |t|
      t.integer :user_id, null: false
      t.integer :issue_id, null: false
      t.integer :weight
      t.datetime_with_timezone :created_at, null: false

      t.index [:user_id], name: 'index_resource_weight_events_on_user_id'
      t.index [:issue_id, :weight], name: 'index_resource_weight_events_on_issue_id_and_weight'
    end

    add_concurrent_foreign_key :resource_weight_events, :users, column: :user_id, on_delete: :cascade
    add_concurrent_foreign_key :resource_weight_events, :issues, column: :issue_id, on_delete: :cascade
  end

  def down
    drop_table :resource_weight_events
  end
end
