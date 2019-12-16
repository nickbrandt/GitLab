# frozen_string_literal: true

class MigrateDesignNotesMentionsToDb < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  DELAY = 2.minutes.to_i
  BATCH_SIZE = 10000
  MIGRATION = 'UserMentions::CreateResourceUserMention'
  INDEX_NAME = 'design_mentions_temp_index'

  class Note < ActiveRecord::Base
    include EachBatch

    self.table_name = 'notes'
  end

  def up
    disable_statement_timeout do
      # create temporary index for notes with mentions, may take well over 1h
      add_concurrent_index(:notes, :id, where: "note ~~ '%@%'::text AND notes.noteable_type = 'DesignManagement::Design' AND notes.system = false", name: INDEX_NAME)
    end

    conditions = "note LIKE '%@%' AND notes.noteable_type = 'DesignManagement::Design' AND design_user_mentions.design_id IS NULL"
    join = "LEFT JOIN design_user_mentions ON notes.id = design_user_mentions.note_id"

    Note
      .joins(join)
      .where(conditions)
      .each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck('MIN(notes.id)', 'MAX(notes.id)').first
      BackgroundMigrationWorker.perform_in(index * DELAY, MIGRATION, ['DesignManagement::Design', join, conditions, true, *range])
    end
  end

  def down
    # no-op
  end
end
