module EE
  module EnvironmentEntity
    extend ActiveSupport::Concern

    prepended do
      expose :logs_path, if: -> (*) { can_read_pod_logs? } do |environment|
        logs_project_environment_path(environment.project, environment)
      end

      expose :deployable_by_user? do |environment|
        environment.protected_deployable_by_user(current_user)
      end
    end

    def can_read_pod_logs?
      can?(current_user, :read_pod_logs, environment.project)
    end
  end
end
