# frozen_string_literal: true

module Ci
  class TriggerDownstreamSubscriptionService < ::BaseService
    def execute(pipeline)
      pipeline.project.downstream_projects.each do |downstream_project|
        ::Ci::CreatePipelineService.new(downstream_project, pipeline.user, ref: downstream_project.default_branch).execute(:pipeline)
      end
    end
  end
end
