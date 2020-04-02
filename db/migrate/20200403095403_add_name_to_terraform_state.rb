# frozen_string_literal: true

class AddNameToTerraformState < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :terraform_states, :name, :string, limit: 255
    add_index :terraform_states, [:project_id, :name], unique: true # rubocop:disable Migration/AddIndex (table not used yet)
  end
end
