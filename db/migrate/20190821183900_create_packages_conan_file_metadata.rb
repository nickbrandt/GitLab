# frozen_string_literal: true

class CreatePackagesConanFileMetadata < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :packages_conan_file_metadata do |t|
      t.references :package_file
      t.string "recipe", null: false
      t.string "path", null: false
      t.string "version", null: false, default: "0"
      t.index %w[package_file_id path], name: "index_packages_maven_metadata_on_package_file_id_and_path", using: :btree

      t.timestamps_with_timezone
    end
  end
end
