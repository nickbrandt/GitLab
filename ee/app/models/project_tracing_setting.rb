# frozen_string_literal: true

class ProjectTracingSetting < ActiveRecord::Base
  belongs_to :project

  validates :external_url, length: { maximum: 255 }, public_url: true

  def self.create_or_update(project, params)
    self.transaction(requires_new: true) do
      tracing_setting = self.for_project(project)
      tracing_setting.update(params)
    end
  rescue ActiveRecord::RecordNotUnique
    retry
  end

  def self.for_project(project)
    self.where(project: project).first_or_initialize
  end
end
