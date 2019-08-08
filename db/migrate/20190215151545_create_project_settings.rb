# frozen_string_literal: true

class CreateProjectSettings < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    create_table(:project_settings, id: false) do |t|
      t.references :project,
                   primary_key: true,
                   null: false,
                   index: { unique: true },
                   foreign_key: { on_delete: :cascade }

      t.boolean :forking_enabled,
                default: true,
                null: false

      t.datetime_with_timezone :updated_at, null: false
    end
  end
end
