module ProtectedEnvironments
  class UpdateService < BaseService
    def execute(protected_environment)
      protected_environment.update(params)
      protected_environment
    end
  end
end
