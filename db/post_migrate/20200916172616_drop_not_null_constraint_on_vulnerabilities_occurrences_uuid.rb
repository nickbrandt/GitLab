# frozen_string_literal: true

class DropNotNullConstraintOnVulnerabilitiesOccurrencesUuid < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    execute <<~SQL
      ALTER TABLE vulnerability_occurrences ALTER COLUMN uuid DROP NOT NULL
    SQL
  end

  def down
    # Should we use
    # add_not_null_constraint(:vulnerability_occurrences, :uuid, validate: false)
    # instead of SET NOT NULL?
    execute <<~SQL
      ALTER TABLE vulnerability_occurrences ALTER COLUMN uuid SET NOT NULL
    SQL
  end
end
