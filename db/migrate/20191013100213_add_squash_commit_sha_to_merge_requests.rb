# frozen_string_literal: true

class AddSquashCommitShaToMergeRequests < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  # disable_ddl_transaction!

  def change
    add_column :merge_requests, :squash_commit_sha, :varchar
  end
end
