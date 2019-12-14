# frozen_string_literal: true

class PlanLimits < ApplicationRecord
  self.primary_key = :plan_id

  belongs_to :plan
end
