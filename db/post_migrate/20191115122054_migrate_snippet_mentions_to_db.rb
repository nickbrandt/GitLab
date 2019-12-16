# frozen_string_literal: true

class MigrateSnippetMentionsToDb < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  DELAY = 2.minutes.to_i
  BATCH_SIZE = 10000
  MIGRATION = 'UserMentions::CreateResourceUserMention'

  class Snippet < ActiveRecord::Base
    include EachBatch

    self.table_name = 'snippets'
  end

  def up
    disable_statement_timeout do
      join = "LEFT JOIN snippet_user_mentions on snippets.id = snippet_user_mentions.snippet_id"
      conditions = "(description LIKE '%@%' OR title LIKE '%@%') AND snippet_user_mentions.snippet_id IS NULL"

      Snippet
        .joins(join)
        .where(conditions)
        .each_batch(of: BATCH_SIZE) do |batch, index|
        range = batch.pluck('MIN(snippets.id)', 'MAX(snippets.id)').first
        BackgroundMigrationWorker.perform_in(index * DELAY, MIGRATION, ['Snippet', join, conditions, false, *range])
      end
    end
  end

  def down
    # no-op
  end
end
