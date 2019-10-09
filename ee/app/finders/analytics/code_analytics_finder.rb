# frozen_string_literal: true

module Analytics
  class CodeAnalyticsFinder
    def initialize(project:, from:, to:, file_count: nil)
      @project = project
      @from = from
      @to = to
      @file_count = file_count
    end

    def execute
      Analytics::CodeAnalytics::RepositoryFileCommit.top_files(
        project: @project,
        from: @from,
        to: @to,
        file_count: @file_count
      )
    end
  end
end
