# frozen_string_literal: true

class ProjectSettings < ApplicationRecord
  belongs_to :project, inverse_of: :settings

  self.primary_key = :project_id
end
