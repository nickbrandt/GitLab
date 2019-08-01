# frozen_string_literal: true

module Analytics
  class ProductivityCalculator
    def initialize(merge_request)
      @merge_request = merge_request
    end

    def productivity_data
      {
        first_comment_at: first_comment_at,
        first_commit_at: first_commit_at,
        last_commit_at: last_commit_at,
        commits_count: commits_count,
        diff_size: diff_size,
        modified_paths_size: modified_paths_size
      }
    end

    private

    attr_reader :merge_request

    delegate :commits_count, :merge_request_diff, to: :merge_request

    def diff_size
      merge_request_diff.lines_count
    end

    def first_comment_at
      merge_request.notes.by_humans.fresh.first&.created_at
    end

    def first_commit_at
      merge_request_diff&.first_commit&.authored_date
    end

    def last_commit_at
      merge_request_diff&.last_commit&.committed_date
    end

    def modified_paths_size
      merge_request.modified_paths.size
    end
  end
end
