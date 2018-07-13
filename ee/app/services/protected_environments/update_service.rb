module ProtectedEnvironments
  class UpdateService < BaseService
    def execute(protected_environment)
      raise Gitlab::Access::AccessDeniedError unless authorized?(protected_environment)

      protected_environment.update(params)
      protected_environment
    end

    def authorized?(protected_environment)
      can?(current_user, :update_protected_environment, protected_environment)
    end
  end
end
