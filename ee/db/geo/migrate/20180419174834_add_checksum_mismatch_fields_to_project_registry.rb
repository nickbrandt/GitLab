class AddChecksumMismatchFieldsToProjectRegistry < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :project_registry, :repository_checksum_mismatch, :boolean, null: false, default: false # rubocop:disable Migration/AddColumn
    add_column :project_registry, :wiki_checksum_mismatch, :boolean, null: false, default: false # rubocop:disable Migration/AddColumn
  end
end
