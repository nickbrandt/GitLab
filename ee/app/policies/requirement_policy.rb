# frozen_string_literal: true

class RequirementPolicy < BasePolicy
  delegate { @subject.resource_parent }
end
