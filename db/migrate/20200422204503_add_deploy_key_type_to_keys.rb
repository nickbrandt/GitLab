# frozen_string_literal: true

class AddDeployKeyTypeToKeys < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :keys, :deploy_key_type, :integer, limit: 2, allow_null: true
  end
end
