# frozen_string_literal: true

module Ci
  # By default this class returns builds for a specific pipeline. If you'd like bridges, use params[:type] bridges. It will never return both.
  class PipelineJobsFinder
    include Gitlab::Allowable

    def initialize(current_user, project, params = {})
      @current_user = current_user
      @project = project
      @params = params
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless can_read_pipelines? && can_read_builds?

      filter_by_scope(init_collection, params[:scope])
    end

    private

    attr_reader :current_user, :project, :params

    def init_collection
      if params[:type] == :bridges
        pipeline.bridges
      else
        pipeline.builds
      end
    end

    def can_read_pipelines?
      Ability.allowed?(current_user, :read_pipeline, project)
    end

    def can_read_builds?
      Ability.allowed?(current_user, :read_build, pipeline)
    end

    def pipeline
      @pipeline ||= project.all_pipelines.find(params[:pipeline_id])
    end

    def filter_by_scope(jobs, scope)
      return jobs unless scope.present?

      available_statuses = ::CommitStatus::AVAILABLE_STATUSES

      unknown = scope - available_statuses
      raise ArgumentError, 'Scope contains invalid value(s)' unless unknown.empty?

      jobs.where(status: scope) # rubocop: disable CodeReuse/ActiveRecord
    end
  end
end
