# frozen_string_literal: true

class DastSite < ApplicationRecord
  belongs_to :project
  has_many :dast_site_profiles

  validates :url, length: { maximum: 255 }, uniqueness: { scope: :project_id }, public_url: true
  validates :project_id, presence: true
end
