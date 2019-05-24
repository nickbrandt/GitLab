# frozen_string_literal: true
module MergeTrains
  class RefreshMergeRequestsService < BaseService
    include ::Gitlab::ExclusiveLeaseHelpers

    ##
    # merge_request ... A merge request pointer in a merge train.
    #                   All the merge requests following the specified merge request will be refreshed.
    def execute(merge_request)
      return unless merge_request.on_train?

      in_lock("merge_train:#{merge_request.target_project_id}-#{merge_request.target_branch}") do
        unsafe_refresh(merge_request)
      end
    end

    private

    def unsafe_refresh(merge_request)
      following_merge_requests_from(merge_request).each do |merge_request|
        MergeTrains::RefreshMergeRequestService
          .new(merge_request.project, merge_request.merge_user)
          .execute(merge_request)
      end
    end

    def following_merge_requests_from(merge_request)
      merge_request.merge_train.all_next.to_a.unshift(merge_request)
    end
  end
end
