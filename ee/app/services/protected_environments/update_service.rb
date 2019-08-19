# frozen_string_literal: true
module ProtectedEnvironments
  class UpdateService < ProtectedEnvironments::BaseService
    def execute(protected_environment)
      protected_environment.update(sanitized_params)
    end
  end
end
