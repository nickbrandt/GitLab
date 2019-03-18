# frozen_string_literal: true

class AddChecksumMismatchedColumndsToProjectRegistry < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :project_registry, :repository_verification_checksum_mismatched, :binary
    add_column :project_registry, :wiki_verification_checksum_mismatched, :binary
  end
end
