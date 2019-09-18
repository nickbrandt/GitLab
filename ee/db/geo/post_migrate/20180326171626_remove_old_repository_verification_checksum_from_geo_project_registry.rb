class RemoveOldRepositoryVerificationChecksumFromGeoProjectRegistry < ActiveRecord::Migration[4.2]
  DOWNTIME = false

  def up
    remove_column :project_registry, :repository_verification_checksum
    remove_column :project_registry, :wiki_verification_checksum
  end

  def down
    add_column :project_registry, :repository_verification_checksum, :string # rubocop:disable Migration/AddLimitToStringColumns
    add_column :project_registry, :wiki_verification_checksum, :string # rubocop:disable Migration/AddLimitToStringColumns
  end
end
