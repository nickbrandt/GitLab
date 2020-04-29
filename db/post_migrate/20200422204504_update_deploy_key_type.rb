# frozen_string_literal: true

class UpdateDeployKeyType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    update_column_in_batches(:keys, :deploy_key_type, 2) do |table, query|
      query.where(table[:type].eq('DeployKey'))
    end
  end

  def down
    # no-op
    # This migration can not be reversed because we can not automatically know which Deploy Keys had
    # their deploy_key_type=2 set when it initially run vs set after the migration
  end
end
