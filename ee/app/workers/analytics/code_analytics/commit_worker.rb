# frozen_string_literal: true

module Analytics
  module CodeAnalytics
    class CommitWorker
      include ApplicationWorker

      queue_namespace :analytics

      # rubocop: disable CodeReuse/ActiveRecord
      def perform(project_id, ref)
        project = Project.find_by(id: project_id)
        return false unless project

        commit = project.repository.commit(ref)
        return false unless commit

        changed_files = commit.diffs.diff_files.each_with_object(Set.new) do |diff_file, set|
          set << diff_file.new_path
        end

        Gitlab::Analytics::CodeAnalytics::RecordInserter.new(
          project: project,
          changed_files: changed_files,
          committed_date: commit.committed_date
        ).execute

        true
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
