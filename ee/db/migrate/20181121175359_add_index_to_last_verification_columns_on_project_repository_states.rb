# frozen_string_literal: true

class AddIndexToLastVerificationColumnsOnProjectRepositoryStates < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  REPOSITORY_INDEX_NAME = 'idx_repository_states_on_last_repository_verification_ran_at'
  WIKI_INDEX_NAME = 'idx_repository_states_on_last_wiki_verification_ran_at'

  disable_ddl_transaction!

  def up
    add_concurrent_index(:project_repository_states,
      [:project_id, :last_repository_verification_ran_at],
      name: REPOSITORY_INDEX_NAME,
      where: 'repository_verification_checksum IS NOT NULL AND last_repository_verification_failure IS NULL')

    add_concurrent_index(:project_repository_states,
      [:project_id, :last_wiki_verification_ran_at],
      name: WIKI_INDEX_NAME,
      where: 'wiki_verification_checksum IS NOT NULL AND last_wiki_verification_failure IS NULL')
  end

  def down
    remove_concurrent_index_by_name(:project_repository_states, REPOSITORY_INDEX_NAME)
    remove_concurrent_index_by_name(:project_repository_states, WIKI_INDEX_NAME)
  end
end
