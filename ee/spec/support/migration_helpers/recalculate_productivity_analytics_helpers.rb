# frozen_string_literal: true

module MigrationHelpers
  module RecalculateProductivityAnalyticsHelpers
    def create_populated_mr(user, project, attributes: {}, metrics: {})
      base = {
        author_id: user.id,
        source_project_id: project.id,
        target_project_id: project.id,
        source_branch: 'master',
        target_branch: 'feature'
      }

      mr = table(:merge_requests).create!(base.merge(attributes))
      table(:merge_request_metrics).create!(metrics.merge(merge_request_id: mr.id))

      create_mr_activity(mr)
      create_notes(mr)

      mr
    end

    def create_notes(mr)
      # 4 notes per MR
      table(:notes).create!(note: 'sample note', noteable_type: 'MergeRequest', noteable_id: mr.id, author_id: user.id, created_at: 4.weeks.ago + 1.day)
      table(:notes).create!(note: 'sample note 2', noteable_type: 'MergeRequest', noteable_id: mr.id, author_id: user.id, created_at: 4.weeks.ago + 2.days)
      table(:notes).create!(note: 'system note', noteable_type: 'MergeRequest', noteable_id: mr.id, created_at: 4.weeks.ago + 3.days)
      table(:notes).create!(note: 'bot note', noteable_type: 'MergeRequest', noteable_id: mr.id, author_id: bot.id, created_at: 4.weeks.ago + 2.days)
    end

    def create_mr_activity(mr)
      diff = table(:merge_request_diffs).create!(merge_request_id: mr.id, commits_count: 2)

      # 2 commits per MR
      table(:merge_request_diff_commits).create!(sha: '456', merge_request_diff_id: diff.id, authored_date: 2.weeks.ago, committed_date: 1.week.ago, relative_order: 0)
      table(:merge_request_diff_commits).create!(sha: '123', merge_request_diff_id: diff.id, authored_date: 4.weeks.ago, committed_date: 3.weeks.ago, relative_order: 1)

      # 2 diff files per MR
      base_diff_files_attributes = {
        merge_request_diff_id: diff.id,
        new_file: true,
        renamed_file: false,
        deleted_file: false,
        too_large: false,
        a_mode: '0',
        b_mode: '160000',
        diff: "@@ -1,6 +1,6 @@\n class Commit\n   constructor: ->\n     $('.files .diff-file').each ->\n-      new CommitFile(this)\n+      new CommitFile(@)\n \n-@Commit = Commit\n+@Commit = Commit\n\\ No newline at end of file\n",
        binary: false
      }

      table(:merge_request_diff_files).create!(
        base_diff_files_attributes.merge(relative_order: 1, new_path: 'test_file', old_path: 'test_file')
      )
      table(:merge_request_diff_files).create!(
        base_diff_files_attributes.merge(relative_order: 2, new_path: 'test_file_2', old_path: 'test_file_2')
      )
    end
  end
end
