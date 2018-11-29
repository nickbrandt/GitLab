class CreateProjectRegistry < ActiveRecord::Migration[4.2]
  def change
    create_table :project_registry do |t|
      t.integer  :project_id, null: false
      t.datetime :last_repository_synced_at
      t.datetime :last_repository_successful_sync_at

      t.datetime :created_at, null: false
    end
  end
end
