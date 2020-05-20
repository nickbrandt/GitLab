# frozen_string_literal: true

class AddUserIdIndexesToCiPipelines < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :ci_pipelines, [:project_id, :user_id, :status]
    add_concurrent_index :ci_pipelines, [:project_id, :user_id, :ref]
  end

  def down
    remove_concurrent_index :ci_pipelines, [:project_id, :user_id, :status]
    remove_concurrent_index :ci_pipelines, [:project_id, :user_id, :ref]
  end
end
