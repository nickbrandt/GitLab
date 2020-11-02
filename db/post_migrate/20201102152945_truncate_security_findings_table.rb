# frozen_string_literal: true

class TruncateSecurityFindingsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      connection.execute('TRUNCATE security_findings RESTART IDENTITY')
    end
  end

  def down
    # no-op
  end
end
