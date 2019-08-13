# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Execution time estimates: 55 records per second,
    # with 3 month period it will be 3.2mln records affected
    # and with 320 batches it will be ~16h total execution time
    class RecalculateProductivityAnalytics
      BATCH_SIZE = 1_000

      METRICS_TO_CALCULATE = %w[first_comment_at first_commit_at last_commit_at diff_size commits_count modified_paths_size].freeze

      module Migratable
        class Metrics < ActiveRecord::Base
          include EachBatch

          belongs_to :merge_request, class_name: 'Migratable::MergeRequest', foreign_key: :merge_request_id, inverse_of: :metrics

          self.table_name = 'merge_request_metrics'
        end

        class MergeRequest < ActiveRecord::Base
          self.table_name = 'merge_requests'

          has_many :diffs, class_name: 'Migratable::MergeRequestDiff', foreign_key: :merge_request_id

          has_many :user_notes, -> { where(noteable_type: 'MergeRequest').where.not(author_id: User.bots) }, class_name: 'Migratable::Note', foreign_key: :noteable_id

          has_one :metrics, class_name: 'Migratable::Metrics', foreign_key: :merge_request_id, inverse_of: :merge_request

          attr_writer :diff, :first_user_note

          def first_user_note
            @first_user_note ||= user_notes.order(created_at: :asc).first
          end

          def diff
            @diff ||= diffs.order(id: :desc).includes(:files).first # max_by(&:id)
          end
        end

        class Note < ActiveRecord::Base
          self.table_name = 'notes'
        end

        class User < ActiveRecord::Base
          self.table_name = 'users'

          def self.bots
            @bots ||= where.not(bot_type: nil).select(:id).to_a
          end
        end

        class MergeRequestDiff < ActiveRecord::Base
          self.table_name = 'merge_request_diffs'

          has_many :commits, class_name: 'Migratable::MergeRequestDiffCommit', foreign_key: :merge_request_diff_id
          has_many :files, class_name: 'Migratable::MergeRequestDiffFile', foreign_key: :merge_request_diff_id

          attr_writer :first_commit, :last_commit

          def first_commit
            @first_commit ||= commits.order(relative_order: :desc).first
          end

          def last_commit
            @last_commit ||= commits.order(relative_order: :desc).last
          end

          def lines_count
            @lines_count ||= Gitlab::Git::DiffCollection.new(files.map(&:to_hash), limits: false).sum(&:line_count)
          end

          def modified_paths
            @modified_paths ||= files.map { |f| [f.new_path, f.old_path] }.flatten.uniq
          end
        end

        class MergeRequestDiffCommit < ActiveRecord::Base
          self.table_name = 'merge_request_diff_commits'
        end

        class MergeRequestDiffFile < ActiveRecord::Base
          include DiffFile

          self.table_name = 'merge_request_diff_files'
        end
      end

      def perform(start_id, end_id)
        Migratable::Metrics.where("merged_at > ? ", 3.months.ago - 1.day)
          .where(id: start_id...end_id).each_batch(of: BATCH_SIZE) do |batch|
          ActiveRecord::Base.transaction do
            preload(batch).each do |merge_request_metrics|
              update_merge_request_metrics(merge_request_metrics)
            end
          end
        end
      end

      private

      def update_merge_request_metrics(metrics)
        merge_request = metrics.merge_request
        diff = merge_request.diff

        return unless diff

        metrics.first_comment_at = merge_request.first_user_note&.created_at
        metrics.first_commit_at = diff.first_commit&.authored_date
        metrics.last_commit_at = diff.last_commit&.committed_date
        metrics.commits_count = diff.commits_count
        metrics.diff_size = diff.lines_count
        metrics.modified_paths_size = diff.modified_paths.size

        metrics.save!
      end

      def preload(metrics_batch)
        metrics_batch.includes(:merge_request).tap do |scope|
          preload_diffs(scope)
          preload_notes(scope)
        end
      end

      def preload_notes(scope)
        first_user_notes_ids = Migratable::Note
          .where(noteable_id: scope.map(&:merge_request_id), noteable_type: 'MergeRequest')
          .where.not(author_id: Migratable::User.bots).group(:noteable_id).pluck(Arel.sql('noteable_id, MIN(id)')).to_h

        notes = Migratable::Note.where(id: first_user_notes_ids.values)

        scope.each do |metric|
          first_note_id = first_user_notes_ids[metric.merge_request_id]
          metric.merge_request.first_user_note = notes.detect { |note| note.id == first_note_id}
        end
      end

      def preload_diffs(scope)
        last_diffs_ids = Migratable::MergeRequestDiff
          .where(merge_request_id: scope.map(&:merge_request_id))
          .group(:merge_request_id)
          .pluck(Arel.sql('merge_request_id, MAX(id)')).to_h

        last_diffs = Migratable::MergeRequestDiff.where(id: last_diffs_ids.values).includes(:files)

        preload_commits(last_diffs)

        scope.each do |metric|
          diff_id = last_diffs_ids[metric.merge_request.id]
          next unless diff_id

          diff = last_diffs.detect { |d| d.id == diff_id }

          metric.merge_request.diff = diff
        end
      end

      def preload_commits(scope)
        commits_map = Migratable::MergeRequestDiffCommit.where(merge_request_diff_id: scope.map(&:id))
          .group(:merge_request_diff_id)
          .pluck(Arel.sql('merge_request_diff_id, MIN(relative_order), MAX(relative_order)'))

        commits_cond = Arel.sql(commits_map.map do |info|
          "(merge_request_diff_id = #{info[0]} AND relative_order IN(#{info[1]}, #{info[2]}))"
        end.join(' OR '))

        commits = Migratable::MergeRequestDiffCommit.where(commits_cond)

        scope.each do |diff|
          related_commits = commits.select { |c| c.merge_request_diff_id == diff.id }

          diff.first_commit = related_commits.max_by(&:relative_order)
          diff.last_commit = related_commits.min_by(&:relative_order)
        end
      end
    end
  end
end
