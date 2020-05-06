# frozen_string_literal: true

class SprintPolicy < BasePolicy
  delegate { @subject.resource_parent }
end
