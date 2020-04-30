# frozen_string_literal: true

module RequirementsManagement
  class UpdateRequirementService < BaseService
    def execute(requirement)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :update_requirement, project)

      attrs = whitelisted_requirement_params
      requirement.update(attrs)

      requirement
    end

    private

    def whitelisted_requirement_params
      params.slice(:title, :state)
    end
  end
end
