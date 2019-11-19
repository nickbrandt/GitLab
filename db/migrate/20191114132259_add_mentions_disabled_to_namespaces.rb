# frozen_string_literal: true

class AddMentionsDisabledToNamespaces < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :namespaces, :mentions_disabled, :boolean
  end
end
