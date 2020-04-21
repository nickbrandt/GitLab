# frozen_string_literal: true

class RenameContainerExpirationPoliciesNameRegexToNameRegexDelete < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    rename_column_concurrently(:container_expiration_policies,
                               :name_regex,
                               :name_regex_delete,
                               batch_column_name: :project_id)
  end

  def down
    undo_rename_column_concurrently(:container_expiration_policies,
                                    :name_regex,
                                    :name_regex_delete)
  end
end
