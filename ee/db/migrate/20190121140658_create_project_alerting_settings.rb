# frozen_string_literal: true

class CreateProjectAlertingSettings < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :project_alerting_settings, id: :int, primary_key: :project_id do |t|
      t.string :encrypted_token, null: false
      t.string :encrypted_token_iv, null: false
      t.foreign_key :projects, column: :project_id, on_delete: :cascade
    end
  end
end
