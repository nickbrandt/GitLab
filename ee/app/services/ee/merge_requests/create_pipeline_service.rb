# frozen_string_literal: true

module EE
  module MergeRequests
    module CreatePipelineService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(merge_request)
        create_merge_request_pipeline_for(merge_request) || super
      end

      def create_merge_request_pipeline_for(merge_request)
        return unless can_create_merge_request_pipeline_for?(merge_request)

        result = ::MergeRequests::MergeToRefService.new(merge_request.project, current_user).execute(merge_request)

        if result[:status] == :success &&
           merge_request.mergeable_state?(skip_ci_check: true, skip_discussions_check: true)

          ::Ci::CreatePipelineService.new(merge_request.source_project, current_user,
                                          ref: merge_request.merge_ref_path,
                                          checkout_sha: result[:commit_id],
                                          target_sha: result[:target_id],
                                          source_sha: result[:source_id])
            .execute(:merge_request_event, merge_request: merge_request)
        end
      end

      def can_create_merge_request_pipeline_for?(merge_request)
        return false unless merge_request.project.merge_pipelines_enabled?
        return false unless can_use_merge_request_ref?(merge_request)

        can_create_pipeline_for?(merge_request)
      end
    end
  end
end
