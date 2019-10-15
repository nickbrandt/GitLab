# frozen_string_literal: true

module Analytics
  module CodeAnalytics
    class RepositoryFileCommit < ApplicationRecord
      DEFAULT_FILE_COUNT = 100
      MAX_FILE_COUNT = 500

      TopFilesLimitError = Class.new(StandardError)

      belongs_to :project
      belongs_to :analytics_repository_file, class_name: 'Analytics::CodeAnalytics::RepositoryFile'

      self.table_name = 'analytics_repository_file_commits'

      def self.files_table
        Analytics::CodeAnalytics::RepositoryFile.arel_table
      end

      def self.top_files(project:, from:, to:, file_count: DEFAULT_FILE_COUNT)
        file_count ||= DEFAULT_FILE_COUNT

        raise TopFilesLimitError if file_count > MAX_FILE_COUNT

        joins(:analytics_repository_file)
          .select(files_table[:id], files_table[:file_path])
          .where(project_id: project.id)
          .where(arel_table[:committed_date].gteq(from))
          .where(arel_table[:committed_date].lteq(to))
          .group(files_table[:id], files_table[:file_path])
          .order(arel_table[:commit_count].sum)
          .limit(file_count)
          .sum(arel_table[:commit_count])
      end

      private_class_method :files_table
    end
  end
end
