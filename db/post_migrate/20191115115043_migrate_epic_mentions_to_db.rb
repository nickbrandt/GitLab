# frozen_string_literal: true

class MigrateEpicMentionsToDb < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  disable_ddl_transaction!

  DELAY = 2.minutes.to_i
  BATCH_SIZE = 10000
  MIGRATION = 'CreateResourceUserMention'

  class Epic < ActiveRecord::Base
    include EachBatch

    self.table_name = 'epics'
  end

  def up
    join = "LEFT JOIN epic_user_mentions on epics.id = epic_user_mentions.epic_id"
    conditions = "(description like '%@%' OR title like '%@%') AND epic_user_mentions.epic_id is null"

    Epic
      .joins(join)
      .where(conditions)
      .each_batch(of: BATCH_SIZE) do |batch, index|
      range = batch.pluck('MIN(epics.id)', 'MAX(epics.id)').first
      BackgroundMigrationWorker.perform_in(index * DELAY, MIGRATION, ['Epic', join, conditions, false, *range])
    end
  end

  def down
    # no-op
  end
end
