# frozen_string_literal: true

class DashboardOperationsProjectEntity < Grape::Entity
  include RequestAwareEntity

  expose :project, merge: true, using: API::Entities::BasicProjectDetails

  expose :remove_path do |dashboard_project|
    remove_operations_project_path(project_id: dashboard_project.project.id)
  end

  expose :last_deployment, if: -> (*) { last_deployment? } do |dashboard_project, options|
    new_request = EntityRequest.new(
      current_user: request.current_user,
      project: dashboard_project.project
    )

    DeploymentEntity.represent(dashboard_project.last_deployment,
                               options.merge(request: new_request))
  end

  expose :alert_count
  expose :alert_path, if: -> (*) { last_deployment? } do |dashboard_project|
    project = dashboard_project.project
    environment = dashboard_project.last_deployment.environment

    metrics_project_environment_path(project, environment)
  end
  expose :last_alert, using: PrometheusAlertEntity, if: -> (*) { last_alert? }

  private

  alias_method :dashboard_project, :object

  def last_deployment?
    dashboard_project.last_deployment
  end

  def last_alert?
    dashboard_project.last_alert
  end
end
