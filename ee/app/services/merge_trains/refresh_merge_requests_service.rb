# frozen_string_literal: true
module MergeTrains
  class RefreshMergeRequestsService < BaseService
    include ::Gitlab::ExclusiveLeaseHelpers

    ##
    # merge_request ... A merge request pointer in a merge train.
    #                   All the merge requests following the specified merge request will be refreshed.
    def execute(merge_request)
      return unless merge_request.on_train?

      if Feature.enabled?(:merge_trains_efficient_refresh, default_enabled: true)
        efficient_refresh(merge_request)
      else
        legacy_refresh(merge_request)
      end
    end

    private

    def efficient_refresh(merge_request)
      queue = Gitlab::BatchPopQueueing.new('merge_trains', queue_id(merge_request))

      result = queue.safe_execute([merge_request.id], lock_timeout: 15.minutes) do |items|
        first_merge_request = MergeTrain.first_in_train_from(items)
        unsafe_refresh(first_merge_request)
      end

      if result[:status] == :finished && result[:new_items].present?
        first_merge_request = MergeTrain.first_in_train_from(result[:new_items])
        AutoMergeProcessWorker.perform_async(first_merge_request.id)
      end
    end

    def legacy_refresh(merge_request)
      in_lock("merge_train:#{merge_request.target_project_id}-#{merge_request.target_branch}") do
        unsafe_refresh(merge_request)
      end
    end

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

    def queue_id(merge_request)
      "#{merge_request.target_project_id}:#{merge_request.target_branch}"
    end
  end
end
