# frozen_string_literal: true

class AddMentioningsDisabledToNamespaces < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :namespaces, :mentionings_disabled, :boolean
  end
end
