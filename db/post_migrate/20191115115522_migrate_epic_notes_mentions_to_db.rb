# frozen_string_literal: true

class MigrateEpicNotesMentionsToDb < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  disable_ddl_transaction!

  DELAY = 2.minutes.to_i
  BATCH_SIZE = 10000
  MIGRATION = 'CreateResourceUserMention'

  class Note < ActiveRecord::Base
    include EachBatch

    self.table_name = 'notes'
  end

  def up
    conditions = "note LIKE '%@%' AND notes.noteable_type = 'Epic' AND epic_user_mentions.epic_id IS NULL"
    join = "INNER JOIN epics ON notes.noteable_id = epics.id LEFT JOIN epic_user_mentions ON notes.id = epic_user_mentions.note_id"

    Note
      .joins(join)
      .where(conditions)
      .each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck('MIN(notes.id)', 'MAX(notes.id)').first
      BackgroundMigrationWorker.perform_in(index * DELAY, MIGRATION, ['Epic', join, conditions, true, *range])
    end
  end

  def down
    # no-op
  end
end
