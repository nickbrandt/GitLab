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

      create_pipeline! if should_create_pipeline?
      merge! if should_merge?

      success
    rescue ProcessError => e
      drop(e)
    end

    private

    def validate!
      unless project.merge_trains_enabled? && project.merge_pipelines_enabled?
        raise ProcessError, 'project disabled merge trains'
      end

      unless merge_request.on_train?
        raise ProcessError, 'merge request is not on a merge train'
      end

      unless merge_request.mergeable_state?(skip_ci_check: true)
        raise ProcessError, 'merge request is not mergeable'
      end

      if pipeline_for_merge_train
        if pipeline_for_merge_train.complete? && !pipeline_for_merge_train.success?
          raise ProcessError, 'pipeline did not succeed'
        end
      end
    end

    def should_create_pipeline?
      first_in_train? && (pipeline_absent? || stale_pipeline?)
    end

    def create_pipeline!
      result = MergeTrains::CreatePipelineService.new(merge_request.project, merge_user)
        .execute(merge_request)

      raise ProcessError, result[:message] unless result[:status] == :success

      merge_train.update!(pipeline: result[:pipeline])
    end

    def should_merge?
      first_in_train? && pipeline_for_merge_train&.success?
    end

    def merge!
      MergeRequests::MergeService.new(project, merge_user, merge_request.merge_params)
                                 .execute(merge_request)

      raise ProcessError, 'failed to merge' unless merge_request.merged?

      merge_train.delete
    end

    def stale_pipeline?
      pipeline_for_merge_train && !pipeline_for_merge_train.latest_merge_request_pipeline?
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

    def merge_user
      merge_request.merge_user
    end

    def first_in_train?
      strong_memoize(:is_first_in_train) do
        merge_train.first_in_train?
      end
    end

    def drop(error)
      AutoMerge::MergeTrainService.new(project, merge_user)
        .cancel(merge_request, reason: error.message, refresh_next: false)

      error(error.message)
    end
  end
end
