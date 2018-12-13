# frozen_string_literal: true

class AddLastVerificationColumnsToProjectRegistry < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :project_registry, :last_repository_verification_ran_at, :datetime_with_timezone
    add_column :project_registry, :last_wiki_verification_ran_at, :datetime_with_timezone
  end
end
