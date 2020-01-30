# frozen_string_literal: true

class MigrateIssueMentionsToDb < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  DELAY = 2.minutes.to_i
  BATCH_SIZE = 10_000
  MIGRATION = 'UserMentions::CreateResourceUserMention'
  INDEX_NAME = 'issues_mentions_temp_index'

  JOIN = "LEFT JOIN issue_user_mentions ON issues.id = issue_user_mentions.issue_id"
  INDEX_CONDITION = "description LIKE '%@%' OR title LIKE '%@%'"
  QUERY_CONDITIONS = "(#{INDEX_CONDITION}) AND issue_user_mentions.issue_id IS NULL"

  class Issue < ActiveRecord::Base
    include EachBatch

    self.table_name = 'issues'
  end

  def up
    Issue
      .joins(JOIN)
      .where(QUERY_CONDITIONS)
      .each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck(Arel.sql('MIN(issues.id)'), Arel.sql('MAX(issues.id)')).first
      migrate_in(index * DELAY, MIGRATION, ['Issue', JOIN, QUERY_CONDITIONS, false, *range])
    end
  end

  def down
    # no-op
  end
end
