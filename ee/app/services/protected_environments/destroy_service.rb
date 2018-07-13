module ProtectedEnvironments
  class DestroyService < BaseService
    def execute(protected_environment)
      raise Gitlab::Access::AccessDeniedError unless authorized?(protected_environment)

      protected_environment.destroy
    end

    def authorized?(protected_environment)
      can?(current_user, :update_protected_environment, protected_environment)
    end
  end
end
