# frozen_string_literal: true

class RemoveOldExternalDiffMigrationIndex < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_concurrent_index_by_name(
      :merge_request_diffs,
      'index_merge_request_diffs_on_merge_request_id_and_id_partial'
    )
  end

  def down
    # rubocop:disable Migration/ComplexIndexesRequireName
    add_concurrent_index(
      :merge_request_diffs,
      [:merge_request_id, :id],
      where: { stored_externally: [nil, false] }
    )
    # rubocop:enable Migration/ComplexIndexesRequireName
  end
end
