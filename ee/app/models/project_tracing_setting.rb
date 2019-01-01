# frozen_string_literal: true

class ProjectTracingSetting < ActiveRecord::Base
  belongs_to :project

  validates :external_url, length: { maximum: 255 }, public_url: true

  before_validation :sanitize_external_url

  private

  def sanitize_external_url
    self.external_url = ActionController::Base.helpers.sanitize(self.external_url, tags: [])
  end
end
