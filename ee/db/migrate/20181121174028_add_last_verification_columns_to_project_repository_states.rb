# frozen_string_literal: true

class AddLastVerificationColumnsToProjectRepositoryStates < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :project_repository_states, :last_repository_verification_ran_at, :datetime_with_timezone
    add_column :project_repository_states, :last_wiki_verification_ran_at, :datetime_with_timezone
  end
end
