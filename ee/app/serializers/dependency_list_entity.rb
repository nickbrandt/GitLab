# frozen_string_literal: true

class DependencyListEntity < Grape::Entity
  include RequestAwareEntity

  present_collection true, :dependencies

  expose :dependencies, using: DependencyEntity
  expose :report do
    expose :status do |list, options|
      status(list[:dependencies], options[:build])
    end

    expose :job_path, if: ->(list, options) { options[:build] && can_read_job_path(options[:build]) } do |_, options|
      project_build_path(project, options[:build].id)
    end
  end

  private

  def can_read_job_path(aa)
    can?(current_user, :read_build, project)
  end

  def current_user
    request.current_user
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
