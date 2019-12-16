# frozen_string_literal: true

class MigrateCommitNotesMentionsToDb < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  DELAY = 2.minutes.to_i
  BATCH_SIZE = 10000
  MIGRATION = 'UserMentions::CreateResourceUserMention'
  INDEX_NAME = 'commit_mentions_temp_index'

  class Note < ActiveRecord::Base
    include EachBatch

    self.table_name = 'notes'
  end

  def up
    disable_statement_timeout do
      # create temporary index for notes with mentions, may take well over 1h
      add_concurrent_index(:notes, :id, where: "note ~~ '%@%'::text AND notes.noteable_type = 'Commit' AND notes.system = false", name: INDEX_NAME)
    end

    conditions = "note LIKE '%@%' AND commit_user_mentions.commit_id IS NULL AND notes.noteable_type = 'Commit'"
    join = "LEFT JOIN commit_user_mentions ON notes.id = commit_user_mentions.note_id"

    Note
      .joins(join)
      .where(conditions)
      .each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck('MIN(notes.id)', 'MAX(notes.id)').first
      BackgroundMigrationWorker.perform_in(index * DELAY, MIGRATION, ['Commit', join, conditions, true, *range])
    end
  end

  def down
    # no-op
  end
end
