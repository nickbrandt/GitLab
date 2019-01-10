# frozen_string_literal: true

module Ci
  class DestroyPipelineService < BaseService
    def execute(pipeline)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_pipeline, pipeline)

      AuditEventService.new(current_user, pipeline, audit_details).security_event

      pipeline.destroy!
    end

    def audit_details
      {
        custom_message: 'Destroyed pipeline'
      }
    end
  end
end
