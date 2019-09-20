# frozen_string_literal: true

class BackfillVersionUserAndCreatedAt < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # no-op for CE
    return unless Gitlab.ee?

    DesignManagement::BackfillVersionDataService.execute
  end

  def down
    # no-op
  end
end
