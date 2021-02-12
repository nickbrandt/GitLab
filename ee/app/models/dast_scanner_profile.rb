# frozen_string_literal: true

class DastScannerProfile < ApplicationRecord
  belongs_to :project

  validates :project_id, presence: true
  validates :name, length: { maximum: 255 }, uniqueness: { scope: :project_id }

  scope :project_id_in, -> (project_ids) { where(project_id: project_ids) }
  scope :with_name, -> (name) { where(name: name) }

  enum scan_type: {
    passive: 1,
    active: 2
  }

  def full_scan_enabled?
    scan_type == 'active'
  end
end
