# frozen_string_literal: true

class CreateInsights < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :insights do |t|
      t.references :namespace, index: true, foreign_key: true, null: false
      t.references :project, index: true, foreign_key: true, null: false
    end
  end
end
