# frozen_string_literal: true

class DashboardEnvironmentEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name
  expose :environment_path do |environment|
    project_environment_path(environment.project, environment)
  end

  expose :external_url
end
