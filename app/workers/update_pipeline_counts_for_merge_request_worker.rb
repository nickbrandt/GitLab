# frozen_string_literal: true

class UpdatePipelineCountsForMergeRequestWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing
  feature_category :continuous_integration
  urgency :high

  deduplicate :until_executed
  idempotent!

  def perform(merge_request_id)
    MergeRequest.find_by_id(merge_request_id).try do |merge_request|
      merge_request.update_pipelines_count
    end
  end
end
