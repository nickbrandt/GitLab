# frozen_string_literal: true

class DashboardEnvironmentEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name
  expose :environment_path do |environment|
    project_environment_path(environment.project, environment)
  end

  expose :external_url

  expose :last_deployment, expose_nil: false do |environment|
    DeploymentEntity.represent(environment.last_deployment, options.merge(request: new_request))
  end

  private

  alias_method :environment, :object

  def new_request
    EntityRequest.new(
      current_user: request.current_user,
      project: environment.project
    )
  end
end
