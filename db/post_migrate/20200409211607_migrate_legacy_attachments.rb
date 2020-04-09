# frozen_string_literal: true

class MigrateLegacyAttachments < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false

  MIGRATION = 'LegacyUploadsMigrator'.freeze
  BATCH_SIZE = 5000
  DELAY_INTERVAL = 5.minutes.to_i

  class Upload < ActiveRecord::Base
    self.table_name = 'uploads'

    include ::EachBatch
  end

  def up
    Upload.where(uploader: 'AttachmentUploader', model_type: 'Note').each_batch(of: BATCH_SIZE) do |relation, index|
      start_id, end_id = relation.pluck('MIN(id), MAX(id)').first
      delay = index * delay_interval

      BackgroundMigrationWorker.perform_in(delay, migration, [start_id, end_id])
    end
  end

  def down
    # no-op
  end
end
