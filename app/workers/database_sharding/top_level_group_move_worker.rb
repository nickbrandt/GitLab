# frozen_string_literal: true

### SETUP COMMANDS
# Update Postgres settings:
#   vim postgresql/data/postgresql.conf
#
#   wal_level = logical
#   max_replication_slots = 10
#
#   gdk stop db
#   gdk start db # For some reason restart did not work
#
# Create a new database with the same schema:
#   pg_dump -h /home/dylan/workspace/gitlab-development-kit/postgresql/ -Fc -s gitlabhq_development > development.dump
#   createdb -h /home/dylan/workspace/gitlab-development-kit/postgresql/ -T template0 gitlabhq_replication_test
#   pg_restore -h /home/dylan/workspace/gitlab-development-kit/postgresql/ -d gitlabhq_replication_test development.dump

module DatabaseSharding
  class TopLevelGroupMoveWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    feature_category :sharding
    idempotent!
    HOST = '/home/dylan/workspace/gitlab-development-kit/postgresql'
    CREATE_REPLICATION_SLOT = "CREATE_REPLICATION_SLOT move_group LOGICAL test_decoding;"
    DROP_REPLICATION_SLOT = "DROP_REPLICATION_SLOT move_group"

    def perform(top_level_group_id)


      result = `psql -h #{HOST} "replication=database dbname=gitlabhq_development" -c "#{DROP_REPLICATION_SLOT}"`
      p result
      # Create a replication slot returning snapshot name

      replication_connection = PG.connect(ActiveRecord::Base.connection.raw_connection.conninfo_hash.compact.merge(replication: 'database'))

      result = replication_connection.exec(CREATE_REPLICATION_SLOT)
      snapshot_name = result[0]['snapshot_name']
      p "snapshot_name: #{snapshot_name}"

      # Restore to new database
      # Pause writes
      # Query replication slot => write to new database
      # Move shard location
      # Drop replication slot
      result = `psql -h #{HOST} "replication=database dbname=gitlabhq_development" -c "#{DROP_REPLICATION_SLOT}"`
      p result
    end
  end
end
