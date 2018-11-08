# frozen_string_literal: true

class AddTracingSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :project_tracing_settings, id: :bigserial do |t|
      t.timestamps_with_timezone null: false

      t.references :project, null: false, foreign_key: { on_delete: :cascade }

      t.string :external_url, null: false

      t.index :project_id,
        unique: true
    end
  end
end
