# frozen_string_literal: true

module EE
  module MergeRequests
    module BaseService
      extend ::Gitlab::Utils::Override

      private

      def filter_params(merge_request)
        unless current_user.can?(:update_approvers, merge_request)
          params.delete(:approvals_before_merge)
          params.delete(:approver_ids)
          params.delete(:approver_group_ids)
        end

        self.params = ApprovalRules::ParamsFilteringService.new(merge_request, current_user, params).execute

        super
      end

      override :create_pipeline_for
      def create_pipeline_for(merge_request, user)
        create_merge_request_pipeline_for(merge_request, user) || super
      end

      def create_merge_request_pipeline_for(merge_request, user)
        return unless can_create_merge_request_pipeline_for?(merge_request)

        result = ::MergeRequests::MergeabilityCheckService.new(merge_request).execute

        if result.success?
          merge_ref_head_payload = result.payload.fetch(:merge_ref_head, {})
          commit_id, target_id, source_id = merge_ref_head_payload.values_at(:commit_id, :target_id, :source_id)

          ::Ci::CreatePipelineService.new(merge_request.source_project, user,
                                          ref: merge_request.merge_ref_path,
                                          checkout_sha: commit_id,
                                          target_sha: target_id,
                                          source_sha: source_id)
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
