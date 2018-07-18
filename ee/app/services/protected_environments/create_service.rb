module ProtectedEnvironments
  class CreateService < BaseService
    def execute
      project.protected_environments.create(params)
    end
  end
end
