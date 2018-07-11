module ProtectedEnvironments
  class CreateService < BaseService
    def execute
      raise Gitlab::Access::AccessDeniedError unless authorized?

      protected_environment.save
      protected_environment
    end

    def authorized?
      #can?(current_user, :create_protected_environment, protected_environment)
      true
    end

    private

    def protected_environment
      @protected_environment ||= project.protected_environments.new(params)
    end
  end
end
