# frozen_string_literal: true

class MigrateSnippetNotesMentionsToDb < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  disable_ddl_transaction!

  DELAY = 2.minutes.to_i
  BATCH_SIZE = 10000
  MIGRATION = 'UserMentions::CreateResourceUserMention'

  class Note < ActiveRecord::Base
    include EachBatch

    self.table_name = 'notes'
  end

  def up
    conditions = "note LIKE '%@%' AND notes.noteable_type = 'Snippet' AND snippet_user_mentions.snippet_id IS NULL"
    join = "LEFT JOIN snippet_user_mentions ON notes.id = snippet_user_mentions.note_id"

    Note
      .joins(join)
      .where(conditions)
      .each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck('MIN(notes.id)', 'MAX(notes.id)').first
      BackgroundMigrationWorker.perform_in(index * DELAY, MIGRATION, ['Snippet', join, conditions, true, *range])
    end
  end

  def down
    # no-op
  end
end
