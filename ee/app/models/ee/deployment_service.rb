# frozen_string_literal: true

module EE
  module DeploymentService
    # Environments have a rollout status. This represents the current state of
    # deployments to that environment.
    def rollout_status(environment)
      raise NotImplementedError
    end
  end
end
