# frozen_string_literal: true

module Gitlab
  module Analytics
    module CodeAnalytics
      class RecordInserter
        BATCH_SIZE = 50

        attr_reader :project, :changed_files, :committed_date

        def initialize(project:, changed_files:, committed_date:)
          @project = project
          @changed_files = changed_files
          @committed_date = committed_date
        end

        def execute
          ActiveRecord::Base.transaction do
            changed_files.each_slice(BATCH_SIZE) do |files|
              execute_query(upsert_files_query(files))
              execute_query(increment_commit_count_query(files))
            end
          end
        end

        private

        def execute_query(query)
          ActiveRecord::Base.connection.execute(Arel.sql(query))
        end

        # Insert new files, ignore when file is already in the DB
        def upsert_files_query(files)
          <<~SQL
          INSERT INTO #{::Analytics::CodeAnalytics::RepositoryFile.table_name} (project_id, file_path)
          VALUES #{values_for_repository_file(files)}
          ON CONFLICT (project_id, file_path) DO NOTHING
          SQL
        end

        # Insert commit count with value `1` for the given date, increment the count if record already exists in the DB
        def increment_commit_count_query(files)
          <<~SQL
          INSERT INTO #{::Analytics::CodeAnalytics::RepositoryFileCommit.table_name} (project_id, analytics_repository_file_id, committed_date, commit_count)
          #{select_repository_files(files)}
          ON CONFLICT (analytics_repository_file_id, committed_date, project_id) DO UPDATE
          SET commit_count = analytics_repository_file_commits.commit_count + 1
          SQL
        end

        def values_for_repository_file(files)
          files.map { |file_path| " (#{project.id}, '#{file_path}')" }.join(',')
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def select_repository_files(files)
          ::Analytics::CodeAnalytics::RepositoryFile
            .where(project_id: project.id, file_path: files)
            .select(Arel.sql("#{project.id}, id, '#{committed_date}', 1"))
            .to_sql
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
