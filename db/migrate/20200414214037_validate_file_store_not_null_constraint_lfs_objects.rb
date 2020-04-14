# frozen_string_literal: true

class ValidateFileStoreNotNullConstraintLfsObjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  CONSTRAINT_NAME = 'lfs_objects_file_store_not_null'
  DOWNTIME = false

  def up
    with_lock_retries do
      execute <<~SQL
        ALTER TABLE lfs_objects VALIDATE CONSTRAINT #{CONSTRAINT_NAME};
      SQL
    end
  end

  def down
    # no-op
  end
end
