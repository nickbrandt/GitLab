# frozen_string_literal: true

module Ci
  class CreateCrossProjectPipelineService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute(bridge)
      @bridge = bridge

      unless target_project_exists?
        return bridge.drop!(:downstream_bridge_project_not_found)
      end

      if target_project == project
        return bridge.drop!(:invalid_bridge_trigger)
      end

      unless can_create_cross_pipeline?
        return bridge.drop!(:insufficient_bridge_permissions)
      end

      create_pipeline!
    end

    private

    def target_project_exists?
      target_project.present? &&
        can?(current_user, :read_project, target_project)
    end

    def can_create_cross_pipeline?
      can?(current_user, :update_pipeline, project) &&
        can?(target_user, :create_pipeline, target_project) &&
          can_update_branch?
    end

    def can_update_branch?
      ::Gitlab::UserAccess.new(target_user, project: target_project).can_update_branch?(target_ref)
    end

    def create_pipeline!
      ::Ci::CreatePipelineService
        .new(target_project, target_user, ref: target_ref)
        .execute(:pipeline, ignore_skip_ci: true) do |pipeline|
          @bridge.sourced_pipelines.build(
            source_pipeline: @bridge.pipeline,
            source_project: @bridge.project,
            project: target_project,
            pipeline: pipeline)

          pipeline.variables.build(@bridge.downstream_variables)
        end
    end

    def target_user
      strong_memoize(:target_user) { @bridge.target_user }
    end

    def target_ref
      strong_memoize(:target_ref) do
        @bridge.target_ref || target_project.default_branch
      end
    end

    def target_project
      strong_memoize(:target_project) do
        Project.find_by_full_path(@bridge.target_project_path)
      end
    end
  end
end
