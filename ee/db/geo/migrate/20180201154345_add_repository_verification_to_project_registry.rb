class AddRepositoryVerificationToProjectRegistry < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def change
    add_column :project_registry, :repository_verification_checksum, :string # rubocop:disable Migration/AddLimitToStringColumns
    add_column :project_registry, :last_repository_verification_at, :datetime_with_timezone
    add_column :project_registry, :last_repository_verification_failed, :boolean, null: false, default: false # rubocop:disable Migration/AddColumn
    add_column :project_registry, :last_repository_verification_failure, :string # rubocop:disable Migration/AddLimitToStringColumns

    add_column :project_registry, :wiki_verification_checksum, :string # rubocop:disable Migration/AddLimitToStringColumns
    add_column :project_registry, :last_wiki_verification_at, :datetime_with_timezone
    add_column :project_registry, :last_wiki_verification_failed, :boolean, null: false, default: false # rubocop:disable Migration/AddColumn
    add_column :project_registry, :last_wiki_verification_failure, :string # rubocop:disable Migration/AddLimitToStringColumns
  end
end
