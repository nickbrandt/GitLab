# frozen_string_literal: true

module Analytics
  class ProductivityRecalculateService
    BATCH_SIZE = 1_000

    def perform(merged_at_after)
      MergeRequest::Metrics.merged_after(merged_at_after).each_batch(of: BATCH_SIZE) do |batch|
        ActiveRecord::Base.transaction do
          merge_requests(batch.map(&:merge_request_id)).each do |merge_request|
            merge_request.metrics.update!(ProductivityCalculator.new(merge_request).productivity_data)
          end
        end
      end
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def merge_requests(ids)
      MergeRequest.where(id: ids)
        .includes(:metrics, :target_project, :source_project,
                  merge_request_diff: [:merge_request_diff_files, :merge_request_diff_commits])
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
