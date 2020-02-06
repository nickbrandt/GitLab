# frozen_string_literal: true

class ProjectSettings < ApplicationRecord
  belongs_to :project, inverse_of: :settings

  self.primary_key = :project_id

  def self.where_or_create_by(attrs)
    where(primary_key => safe_find_or_create_by(attrs))
  end
end
