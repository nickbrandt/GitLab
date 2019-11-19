# frozen_string_literal: true

module Analytics
  class CodeAnalyticsFinder
    RepositoryFileCommitCount = Struct.new(:repository_file, :count)

    def initialize(project:, from:, to:, file_count: nil)
      @project = project
      @from = from
      @to = to
      @file_count = file_count
    end

    def execute
      result.map do |(id, file_path), count|
        RepositoryFileCommitCount.new(
          Analytics::CodeAnalytics::RepositoryFile.new(id: id, file_path: file_path),
          count
        )
      end
    end

    private

    def result
      @result ||= Analytics::CodeAnalytics::RepositoryFileCommit.top_files(
        project: @project,
        from: @from,
        to: @to,
        file_count: @file_count
      )
    end
  end
end
