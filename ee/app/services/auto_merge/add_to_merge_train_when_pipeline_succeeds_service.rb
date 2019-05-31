# frozen_string_literal: true

module AutoMerge
  class AddToMergeTrainWhenPipelineSucceedsService < AutoMerge::BaseService
    def execute(merge_request)
      super do
        SystemNoteService.add_to_merge_train_when_pipeline_succeeds(merge_request, project, current_user, merge_request.diff_head_commit)
      end
    end

    def process(merge_request)
      return unless merge_request.actual_head_pipeline&.success?

      merge_train_service = AutoMerge::MergeTrainService.new(project, merge_request.merge_user)

      ##
      # We are currently abusing `#cancel` method to cancel the auto merge when
      # a system failure happens. We should split the interfaces into two
      # for explicitly telling that the cancel action is not triggered by the merge user directly.
      # https://gitlab.com/gitlab-org/gitlab-ee/issues/12134
      return cancel(merge_request) unless merge_train_service.available_for?(merge_request)

      merge_train_service.execute(merge_request)
    end

    def cancel(merge_request)
      super(merge_request) do
        SystemNoteService.cancel_add_to_merge_train_when_pipeline_succeeds(merge_request, project, current_user)
      end
    end

    def available_for?(merge_request)
      merge_request.project.merge_trains_enabled? &&
        !merge_request.for_fork? &&
        merge_request.actual_head_pipeline&.active? &&
        merge_request.mergeable_state?(skip_ci_check: true)
    end
  end
end
