# frozen_string_literal: true

class AddVerificationStateToLfsObjects < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_table(:lfs_objects) do |t|
      t.integer :verification_state, default: 0, limit: 2, null: false
      t.column :verification_started_at, :datetime_with_timezone
      t.integer :verification_retry_count, limit: 2
      t.column :verification_retry_at, :datetime_with_timezone
      t.column :verified_at, :datetime_with_timezone
      t.binary :verification_checksum, using: 'verification_checksum::bytea'

      # rubocop:disable Migration/AddLimitToTextColumns
      t.text :verification_failure
      # rubocop:enable Migration/AddLimitToTextColumns
    end
  end
end
