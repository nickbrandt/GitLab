# frozen_string_literal: true

class DependencyListEntity < Grape::Entity
  include RequestAwareEntity

  present_collection true, :dependencies

  expose :dependencies, using: DependencyEntity
  expose :report do
    expose :status do |list, options|
      status(list[:dependencies], options[:build])
    end

    expose :job_path, if: ->(_, options) { options[:build] && can_read_job_path? } do |_, options|
      project_build_path(project, options[:build].id)
    end

    expose :generated_at, if: ->(_, options) { options[:build] && can_read_job_path? } do |_, options|
      options[:build].finished_at
    end
  end

  private

  def can_read_job_path?
    can?(request.user, :read_pipeline, project)
  end

  def project
    request.project
  end

  def status(dependencies, build)
    if build&.success?
      if dependencies.any?
        :ok
      else
        :no_dependencies
      end
    elsif build&.failed?
      :job_failed
    else
      :job_not_set_up
    end
  end
end
