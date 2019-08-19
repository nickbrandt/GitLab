# frozen_string_literal: true
module ProtectedEnvironments
  class CreateService < ProtectedEnvironments::BaseService
    def execute
      project.protected_environments.create(sanitized_params)
    end
  end
end
