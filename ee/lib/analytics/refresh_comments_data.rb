# frozen_string_literal: true

module Analytics
  class RefreshCommentsData
    include MergeRequestMetricsRefresh

    # rubocop: disable CodeReuse/ActiveRecord
    def self.for_note(note)
      if note.for_commit?
        merge_requests = note.noteable.merge_requests.includes(:metrics)
      elsif note.for_merge_request?
        merge_requests = [note.noteable]
      else
        return
      end

      new(*merge_requests)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def metric_already_present?(metrics)
      metrics.first_comment_at
    end

    def update_metric!(metrics)
      metrics.update!(
        first_comment_at: MergeRequestMetricsCalculator.new(metrics.merge_request).first_comment_at
      )
    end
  end
end
