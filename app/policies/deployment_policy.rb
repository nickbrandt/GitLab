# frozen_string_literal: true

class DeploymentPolicy < BasePolicy
  prepend EE::DeploymentPolicy

  delegate { @subject.project }
end
