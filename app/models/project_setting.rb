# frozen_string_literal: true

class ProjectSetting < ApplicationRecord
  self.primary_key = :project_id

  belongs_to :project

  validates :forking_enabled, inclusion: { in: [true, false] }
end
