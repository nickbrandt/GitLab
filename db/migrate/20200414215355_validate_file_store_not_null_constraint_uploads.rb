# frozen_string_literal: true

class ValidateFileStoreNotNullConstraintUploads < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  CONSTRAINT_NAME = 'uploads_store_not_null'
  DOWNTIME = false

  def up
    with_lock_retries do
      execute <<~SQL
        ALTER TABLE uploads VALIDATE CONSTRAINT #{CONSTRAINT_NAME};
      SQL
    end
  end

  def down
    # no-op
  end
end
