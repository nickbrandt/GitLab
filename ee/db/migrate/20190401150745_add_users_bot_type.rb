# frozen_string_literal: true

class AddUsersBotType < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    change_table :users do |t|
      t.integer :bot_type, limit: 2
    end
  end
end
