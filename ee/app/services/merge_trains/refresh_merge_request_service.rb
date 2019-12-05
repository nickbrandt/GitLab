# frozen_string_literal: true
module MergeTrains
  class RefreshMergeRequestService < BaseService
    include Gitlab::Utils::StrongMemoize

    ProcessError = Class.new(StandardError)

    attr_reader :merge_request

    ##
    # Arguments:
    # merge_request ... The merge request to be refreshed
    def execute(merge_request)
      @merge_request = merge_request

      validate!
      pipeline_created = create_pipeline! if should_create_pipeline?
      merge! if should_merge?

      success(pipeline_created: pipeline_created.present?)
    rescue ProcessError => e
      abort(e)
    end

    private

    def validate!
      unless project.merge_trains_enabled?
        raise ProcessError, 'project disabled merge trains'
      end

      unless merge_request.on_train?
        raise ProcessError, 'merge request is not on a merge train'
      end

      if merge_request.squash?
        raise ProcessError, 'merge train does not support squash merge'
      end

      unless merge_request.mergeable_state?(skip_ci_check: true)
        raise ProcessError, 'merge request is not mergeable'
      end

      unless previous_ref_exist?
        raise ProcessError, 'previous ref does not exist'
      end

      if pipeline_for_merge_train
        if pipeline_for_merge_train.complete? && !pipeline_for_merge_train.success?
          raise ProcessError, 'pipeline did not succeed'
        end
      end
    end

    # Since `stale_pipeline?` is expensive process which requires multiple Gitaly calls,
    # each refresh service relays `require_recreate` flag whether the next
    # merge request obviously requires to re-create pipeline for merge train.
    def should_create_pipeline?
      pipeline_absent? || require_recreate? || stale_pipeline?
    end

    def create_pipeline!
      result = MergeTrains::CreatePipelineService.new(merge_request.project, merge_user)
        .execute(merge_request, previous_ref)

      raise ProcessError, result[:message] unless result[:status] == :success

      cancel_pipeline_for_merge_train(result[:pipeline])
      update_pipeline_for_merge_train(result[:pipeline])
    end

    def should_merge?
      first_in_train? && pipeline_for_merge_train&.success?
    end

    def merge!
      MergeRequests::MergeService.new(project, merge_user, merge_request.merge_params)
                                 .execute(merge_request)

      raise ProcessError, "failed to merge. #{merge_request.merge_error}" unless merge_request.merged?
    end

    # NOTE: This method works for both no-ff-merge and ff-merge, however,
    #       it doesn't work for squash and merge option.
    def stale_pipeline?
      return true unless pipeline_for_merge_train.source_sha == merge_request.diff_head_sha
      return false if pipeline_for_merge_train.target_sha == previous_ref_sha

      ##
      # Now `pipeline.target_sha` and `previous_ref_sha` are different. This case
      # happens in the following cases:
      # 1. Previous sha has a completely different history from the pipeline.target_sha.
      #    e.g. Previous merge request was dropped from the merge train.
      # 2. Previous sha has exactly the same history with the pipeline.target_sha.
      #    e.g. Previous merge request was merged into target branch with no-ff option.
      #
      # We distinguish these two cases by comparing parent commits.
      commits = merge_request.project.commits_by(oids: [pipeline_for_merge_train.target_sha, previous_ref_sha])
      commits[0].parent_ids != commits[1].parent_ids
    end

    def pipeline_absent?
      !pipeline_for_merge_train.present?
    end

    def merge_train
      merge_request.merge_train
    end

    def pipeline_for_merge_train
      merge_train.pipeline
    end

    def cancel_pipeline_for_merge_train(new_pipeline)
      pipeline_for_merge_train&.auto_cancel_running(new_pipeline, retries: 1)
    rescue ActiveRecord::StaleObjectError
      # Often the pipeline has already been canceled by the default cancelaltion
      # mechanizm `Ci::CreatePipelineService#cancel_pending_pipelines`. In this
      # case, we can ignore the exception as it's already canceled.
    end

    def update_pipeline_for_merge_train(pipeline)
      merge_train.update!(pipeline: pipeline)
    end

    def merge_user
      merge_request.merge_user
    end

    def first_in_train?
      strong_memoize(:is_first_in_train) do
        merge_train.first_in_train?
      end
    end

    def previous_ref_sha
      strong_memoize(:previous_ref_sha) do
        merge_request.project.repository.commit(previous_ref)&.sha
      end
    end

    def previous_ref
      previous_merge_request&.train_ref_path || merge_request.target_branch_ref
    end

    def previous_ref_exist?
      previous_ref_sha.present?
    end

    def previous_merge_request
      strong_memoize(:previous_merge_request) do
        merge_request.merge_train.prev
      end
    end

    def require_recreate?
      params[:require_recreate]
    end

    def abort(error)
      AutoMerge::MergeTrainService.new(project, merge_user)
        .abort(merge_request, error.message, process_next: false)

      error(error.message)
    end
  end
end
