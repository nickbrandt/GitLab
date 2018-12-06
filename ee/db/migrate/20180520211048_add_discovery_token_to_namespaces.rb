# frozen_string_literal: true

class AddDiscoveryTokenToNamespaces < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :namespaces, :saml_discovery_token, :string
  end
end
