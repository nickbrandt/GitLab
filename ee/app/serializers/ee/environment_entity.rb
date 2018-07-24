module EE
  module EnvironmentEntity
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      expose :logs_path, if: -> (*) { can_read_pod_logs? } do |environment|
        logs_project_environment_path(environment.project, environment)
      end

      expose :can_deploy?, as: :can_deploy do |environment|
        environment.protected_deployable_by_user(current_user)
      end

      expose :protected?, as: :is_protected do |environment|
        environment.protected?
      end
    end

    private

    def can_read_pod_logs?
      can?(current_user, :read_pod_logs, environment.project)
    end

    override :can_access_terminal?
    def can_access_terminal?
      if environment.protected?
        environment.protected_deployable_by_user(current_user) &&
          maintainer_or_admin?
      else
        super
      end
    end

    def maintainer_or_admin?
      maintainer? || current_user.admin? 
    end

    def maintainer?
      access_level >= ::Gitlab::Access::MAINTAINER
    end

    def access_level
      return -1 if current_user.nil?

      environment.project.team.max_member_access(current_user.id)
    end
  end
end
