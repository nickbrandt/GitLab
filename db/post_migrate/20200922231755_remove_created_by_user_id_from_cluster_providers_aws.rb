# frozen_string_literal: true

class RemoveCreatedByUserIdFromClusterProvidersAws < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      remove_column :cluster_providers_aws, :created_by_user_id
    end
  end

  def down
    unless column_exists?(:cluster_providers_aws, :created_by_user_id)
      add_column :cluster_providers_aws, :created_by_user_id, :integer
    end

    add_concurrent_index :cluster_providers_aws, :created_by_user_id

    add_concurrent_foreign_key :cluster_providers_aws, :users, column: :created_by_user_id, on_delete: :nullify
  end
end
