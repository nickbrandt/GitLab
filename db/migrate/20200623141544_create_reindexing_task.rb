# frozen_string_literal: true

class CreateReindexingTask < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :reindexing_tasks do |t|
      t.timestamps_with_timezone null: false
      t.integer :documents_count
      t.integer :stage, null: false, default: 0, limit: 2, index: true
      t.text :index_name_from
      t.text :index_name_to
      t.text :elastic_task
      t.text :error_message
    end

    add_text_limit :reindexing_tasks, :index_name_from, 255
    add_text_limit :reindexing_tasks, :index_name_to, 255
    add_text_limit :reindexing_tasks, :elastic_task, 255
    add_text_limit :reindexing_tasks, :error_message, 255
  end

  def down
    drop_table :reindexing_tasks
  end
end
