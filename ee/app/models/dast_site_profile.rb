# frozen_string_literal: true

class DastSiteProfile < ApplicationRecord
  belongs_to :project
  belongs_to :dast_site

  validates :name, length: { maximum: 255 }, uniqueness: { scope: :project_id }
  validates :project_id, :dast_site_id, presence: true
  validate :dast_site_project_id_fk

  private

  def dast_site_project_id_fk
    unless project_id == dast_site&.project_id
      errors.add(:project_id, 'does not match dast_site.project')
    end
  end
end
