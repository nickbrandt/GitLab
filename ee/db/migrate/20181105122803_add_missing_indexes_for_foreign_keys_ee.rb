# frozen_string_literal: true

class AddMissingIndexesForForeignKeysEE < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:application_settings, :file_template_project_id)
    add_concurrent_index(:application_settings, :custom_project_templates_group_id)
    add_concurrent_index(:board_assignees, :assignee_id)
    add_concurrent_index(:board_labels, :label_id)

    # This index has been hoisted up to `20180209115333_create_chatops_tables.rb`
    # so that it could be ported to Core without breaking upgrades
    add_concurrent_index(:ci_pipeline_chat_data, :chat_name_id) unless index_exists?(:ci_pipeline_chat_data, :chat_name_id)

    add_concurrent_index(:geo_node_namespace_links, :namespace_id)
    add_concurrent_index(:namespaces, :file_template_project_id)
    add_concurrent_index(:protected_branch_merge_access_levels, :group_id)
    add_concurrent_index(:protected_branch_push_access_levels, :group_id)
    add_concurrent_index(:software_license_policies, :software_license_id)
  end

  def down
    # MySQL requires index for FK,
    # thus removal of indexes does fail
    return if Gitlab::Database.mysql?

    remove_concurrent_index(:application_settings, :file_template_project_id)
    remove_concurrent_index(:application_settings, :custom_project_templates_group_id)
    remove_concurrent_index(:board_assignees, :assignee_id)
    remove_concurrent_index(:board_labels, :label_id)
    remove_concurrent_index(:geo_node_namespace_links, :namespace_id)
    remove_concurrent_index(:namespaces, :file_template_project_id)
    remove_concurrent_index(:protected_branch_merge_access_levels, :group_id)
    remove_concurrent_index(:protected_branch_push_access_levels, :group_id)
    remove_concurrent_index(:software_license_policies, :software_license_id)
  end
end
