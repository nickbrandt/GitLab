# frozen_string_literal: true
class AddResourceAccessTokensEnabledToNamespaceSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :namespace_settings, :resource_access_tokens_enabled, :boolean, default: true, null: false
    end
  end

  def down
    with_lock_retries do
      remove_column :namespace_settings, :resource_access_tokens_enabled
    end
  end
end
