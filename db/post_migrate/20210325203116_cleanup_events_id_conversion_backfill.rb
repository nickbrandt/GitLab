# frozen_string_literal: true

class CleanupEventsIdConversionBackfill < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    finish_backfill_conversion_of_integer_to_bigint :events, :id
  end

  def down
    # no op
  end
end
