# frozen_string_literal: true

module Analytics
  class CodeReviewMetricsWorker
    include ApplicationWorker

    feature_category :code_analytics

    idempotent!

    def perform(operation, merge_request_id, **execute_args)
      ::MergeRequest.find_by_id(merge_request_id).try do |merge_request|
        break unless merge_request.project.feature_available?(:code_review_analytics)

        operation_klass = operation.constantize
        operation_klass.new(merge_request).execute(**execute_args)
      end
    end
  end
end
