# frozen_string_literal: true

class TriggerBackgroundMigrationForUserDetails < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  # 360K users
  #
  DOWNTIME = false
  INTERVAL = 2.minutes.to_i
  BATCH_SIZE = 1_000
  MIGRATION = 'MigrateToUserDetails'

  disable_ddl_transaction!

  class User < ActiveRecord::Base
    self.table_name = 'users'

    include ::EachBatch
  end

  def up
    relation = User.where("(COALESCE(bio, '') IS DISTINCT FROM '') OR (COALESCE(location, '') IS DISTINCT FROM '') OR (COALESCE(organization, '') IS DISTINCT FROM '') OR (COALESCE(linkedin, '') IS DISTINCT FROM '') OR (COALESCE(twitter, '') IS DISTINCT FROM '') OR (COALESCE(skype, '') IS DISTINCT FROM '') OR (COALESCE(website_url, '') IS DISTINCT FROM '')")

    queue_background_migration_jobs_by_range_at_intervals(relation,
                                                          MIGRATION,
                                                          INTERVAL,
                                                          batch_size: BATCH_SIZE)
  end

  def down
    # no-op
  end
end
