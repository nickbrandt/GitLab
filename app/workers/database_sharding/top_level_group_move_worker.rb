# frozen_string_literal: true

### SETUP COMMANDS
# Install postgres plugin https://github.com/michaelpq/pg_plugins/tree/master/decoder_raw
#   git clone https://github.com/michaelpq/pg_plugins.git
#   edit the Makefile to only install decoder_raw and remove pg_mark_glibc thing
#   make install
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
# Drop foreign keys for things we aren't yet copying across
#   namespaces:
#   ALTER TABLE namespaces DROP CONSTRAINT "fk_319256d87a"; -- FOREIGN KEY (file_template_project_id) REFERENCES projects(id) ON DELETE SET NULL
#   ALTER TABLE namespaces DROP CONSTRAINT "fk_3448c97865"; -- FOREIGN KEY (push_rule_id) REFERENCES push_rules(id) ON DELETE SET NULL
#   ALTER TABLE namespaces DROP CONSTRAINT "fk_e7a0b20a6b"; -- FOREIGN KEY (custom_project_templates_group_id) REFERENCES namespaces(id) ON DELETE SET NULL
#   projects:
#   ALTER TABLE projects DROP CONSTRAINT "fk_6e5c14658a"; -- FOREIGN KEY (pool_repository_id) REFERENCES pool_repositories(id) ON DELETE SET NULL
#   ALTER TABLE projects DROP CONSTRAINT "fk_25d8780d11"; -- FOREIGN KEY (marked_for_deletion_by_user_id) REFERENCES users(id) ON DELETE SET NULL
#   issues:
#   ALTER TABLE issues DROP CONSTRAINT "fk_05f1e72feb"; -- FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE SET NULL
#   ALTER TABLE issues DROP CONSTRAINT "fk_3b8c72ea56"; -- FOREIGN KEY (sprint_id) REFERENCES sprints(id) ON DELETE SET NULL
#   ALTER TABLE issues DROP CONSTRAINT "fk_96b1dd429c"; -- FOREIGN KEY (milestone_id) REFERENCES milestones(id) ON DELETE SET NULL
#   ALTER TABLE issues DROP CONSTRAINT "fk_9c4516d665"; -- FOREIGN KEY (duplicated_to_id) REFERENCES issues(id) ON DELETE SET NULL
#   ALTER TABLE issues DROP CONSTRAINT "fk_a194299be1"; -- FOREIGN KEY (moved_to_id) REFERENCES issues(id) ON DELETE SET NULL
#   ALTER TABLE issues DROP CONSTRAINT "fk_c63cbf6c25"; -- FOREIGN KEY (closed_by_id) REFERENCES users(id) ON DELETE SET NULL
#   ALTER TABLE issues DROP CONSTRAINT "fk_df75a7c8b8"; -- FOREIGN KEY (promoted_to_epic_id) REFERENCES epics(id) ON DELETE SET NULL
#   ALTER TABLE issues DROP CONSTRAINT "fk_ffed080f01"; -- FOREIGN KEY (updated_by_id) REFERENCES users(id) ON DELETE SET NULL

module DatabaseSharding
  class TopLevelGroupMoveWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    sidekiq_options retry: 3

    feature_category :sharding
    idempotent!
    HOST = '/home/dylan/workspace/gitlab-development-kit/postgresql'
    CREATE_REPLICATION_SLOT = "CREATE_REPLICATION_SLOT move_group LOGICAL decoder_raw;"
    DROP_REPLICATION_SLOT = "DROP_REPLICATION_SLOT move_group;"

    def perform(top_level_group_id)
      source_connection = ActiveRecord::Base.connection.raw_connection
      replication_connection = PG.connect(source_connection.conninfo_hash.compact.merge(replication: 'database'))

      # Create a replication slot returning snapshot name
      result = replication_connection.exec(CREATE_REPLICATION_SLOT)
      snapshot_name = result[0]['snapshot_name']
      p "snapshot_name: #{snapshot_name}"

      # Restore to new database
      top_level_group = Namespace.find(top_level_group_id)
      namespace_ids = top_level_group.self_and_descendants.pluck(:id)
      project_ids = top_level_group.all_projects.pluck(:id)
      tables = {namespaces: [:id, namespace_ids], projects: [:namespace_id, namespace_ids], issues: [:project_id, project_ids]}

      tables.each do |table, column_mapping|
        begin
          tmp = Tempfile.new("replication-#{table}")
          tmp.close

          query = <<~SQL
          BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
          SET TRANSACTION SNAPSHOT '#{snapshot_name}';
          \\copy (select * from #{table} where #{column_mapping[0]} IN (#{column_mapping[1].join(",")})) TO '#{tmp.path}' WITH DELIMITER ',' CSV HEADER;
          SQL
          query_file = Tempfile.new("query-#{table}")
          query_file.write(query)
          query_file.close

          `psql --host=#{replication_connection.host} -f #{query_file.path} #{replication_connection.db}`
          `psql --host=#{replication_connection.host} gitlabhq_replication_test -c "\\copy #{table} from '#{tmp.path}' WITH DELIMITER ',' CSV HEADER;"`
        ensure
          tmp&.unlink
          query_file.unlink
        end
      end

      # Try to consume some of replication slot to be "almost" caught up
      destination_connection = PG.connect(source_connection.conninfo_hash.compact.merge(dbname: 'gitlabhq_replication_test'))

      while true
        updates = source_connection.exec("SELECT * FROM pg_logical_slot_get_changes('move_group', NULL, NULL)")
        updates.each do |update|
          query = update['data']
          next unless tables.any? do |table_name,_|
            query.start_with?("INSERT INTO public.#{table_name}") || query.start_with?("UPDATE public.#{table_name}")
          end
          p query
          destination_connection.exec(query)
        end

        sleep 1
      end

      # Pause writes

      # Acquire a current LSN from source database
      response = source_connection.exec('SELECT pg_current_wal_lsn();');
      location = response.first['pg_current_wal_lsn'];
      p location

      # Consume the rest of the replication slot up to the LSN (using upto_lsn argument to pg_logical_slot_get_changes)

      # Move shard location

      # Unpause writes
    ensure
      # Drop replication slot
      replication_connection&.exec(DROP_REPLICATION_SLOT)
    end
  end
end
