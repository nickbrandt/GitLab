# frozen_string_literal: true

class AddAuthorIdIndexToAuditEvents < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  INDEX_NAME = 'index_on_author_id_and_entity_id_and_entity_type_and_id_desc'.freeze

  def up
    add_concurrent_index(:audit_events, [:author_id, :entity_id, :entity_type, :id], order: { id: :desc }, name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(:audit_events, INDEX_NAME)
  end
end
