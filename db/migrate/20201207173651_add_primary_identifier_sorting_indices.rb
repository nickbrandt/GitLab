# frozen_string_literal: true

class AddPrimaryIdentifierSortingIndices < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  OCCURRENCES_INDEX_NAME = 'index_vulnerability_occurrences_on_identifier_and_vulnerability'
  ASC_IDENTIFIERS_INDEX_NAME = 'index_vulnerability_identifiers_sorted_asc_by_external_id'
  DESC_IDENTIFIERS_INDEX_NAME = 'index_vulnerability_identifiers_sorted_desc_by_external_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :vulnerability_occurrences, [:primary_identifier_id, :vulnerability_id], name: OCCURRENCES_INDEX_NAME
    add_concurrent_index :vulnerability_identifiers, [:project_id, :external_id, :id], order: { external_id: :asc, id: :desc }, name: ASC_IDENTIFIERS_INDEX_NAME
    add_concurrent_index :vulnerability_identifiers, [:project_id, :external_id, :id], order: { external_id: :desc, id: :desc }, name: DESC_IDENTIFIERS_INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :vulnerability_occurrences, OCCURRENCES_INDEX_NAME
    remove_concurrent_index_by_name :vulnerability_identifiers, ASC_IDENTIFIERS_INDEX_NAME
    remove_concurrent_index_by_name :vulnerability_identifiers, DESC_IDENTIFIERS_INDEX_NAME
  end
end
