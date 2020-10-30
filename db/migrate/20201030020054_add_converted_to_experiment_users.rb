# frozen_string_literal: true

class AddConvertedToExperimentUsers < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :experiment_users, :converted, :boolean, default: false, null: false
  end
end
