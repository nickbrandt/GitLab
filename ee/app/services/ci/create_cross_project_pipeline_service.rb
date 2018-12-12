# frozen_string_literal: true

module Ci
  class CreateCrossProjectPipelineService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute(bridge)
      @bridge = bridge

      unless can_create_cross_pipeline?
        return bridge.drop!(:insufficient_permissions)
      end

      create_pipeline do |pipeline|
        source = bridge.sourced_pipelines.build(
          source_pipeline: bridge.pipeline,
          source_project: bridge.project,
          project: target_project,
          pipeline: pipeline)

        pipeline.source_pipeline = source
      end
    end

    private

    def can_create_cross_pipeline?
      # TODO should we check update_pipeline in the first condition?
      #
      can?(current_user, :create_pipeline, project) &&
        can?(current_user, :create_pipeline, target_project) &&
        can?(@bridge.target_user, :create_pipeline, target_project)
    end

    def create_pipeline
      ::Ci::CreatePipelineService
        .new(target_project, @bridge.target_user, ref: @bridge.target_ref)
        .execute(:pipeline, ignore_skip_ci: true) do |pipeline|
          yield pipeline
        end
    end

    def target_project
      strong_memoize(:target_project) do
        Project.find_by_full_path(@bridge.target_project_name)
      end
    end
  end
end
