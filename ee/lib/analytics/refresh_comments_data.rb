# frozen_string_literal: true

module Analytics
  class RefreshCommentsData
    # rubocop: disable CodeReuse/ActiveRecord
    def self.for_note(note)
      if note.for_commit?
        merge_requests = note.noteable.merge_requests.includes(:metrics)
      elsif note.for_merge_request?
        merge_requests = [note.noteable]
      else
        return
      end

      new(merge_requests)
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def initialize(merge_requests)
      @merge_requests = merge_requests
    end

    def execute(force: false)
      merge_requests.each do |mr|
        metrics = mr.ensure_metrics

        next if !force && metrics.first_comment_at

        metrics.update!(first_comment_at: ProductivityCalculator.new(mr).first_comment_at)
      end
    end

    private

    attr_reader :merge_requests
  end
end
