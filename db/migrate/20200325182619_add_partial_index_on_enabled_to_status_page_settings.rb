# frozen_string_literal: true

class AddPartialIndexOnEnabledToStatusPageSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'status_page_settings_project_id_enabled_eq_true_partial'

  def up
    add_concurrent_index :status_page_settings, :project_id, name: INDEX_NAME, where: "enabled = true"
  end

  def down
    remove_concurrent_index_by_name :status_page_settings, INDEX_NAME
  end
end
