# frozen_string_literal: true

class DashboardEnvironmentEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name
  expose :environment_path do |environment|
    project_environment_path(environment.project, environment)
  end

  expose :external_url

  expose :last_visible_deployment, as: :last_deployment, expose_nil: false do |environment|
    DeploymentEntity.represent(environment.last_visible_deployment, options.merge(request: request_with_project))
  end

  private

  alias_method :environment, :object

  def request_with_project
    EntityRequest.new(
      current_user: request.current_user,
      project: environment.project
    )
  end
end
