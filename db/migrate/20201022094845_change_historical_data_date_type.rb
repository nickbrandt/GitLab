# frozen_string_literal: true

class ChangeHistoricalDataDateType < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    execute(
      <<SQL
      create or replace function change_historical_date_to_timetamptz(date)
        returns timestamptz
        language sql
        as
      $$
        SELECT ($1 + '12:00'::time) AT TIME ZONE '#{Time.zone&.tzinfo&.name || "Etc/UTC"}'
      $$
SQL
    )

    change_column_type_concurrently(:historical_data, :date, :timestamptz, type_cast_function: "change_historical_date_to_timetamptz")

    execute("DROP FUNCTION IF EXISTS change_historical_date_to_timetamptz")
  end

  def down
    undo_change_column_type_concurrently(:historical_data, :date)
  end
end
