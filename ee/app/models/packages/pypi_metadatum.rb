# frozen_string_literal: true

class Packages::PypiMetadatum < ApplicationRecord
  self.primary_key = :package_id

  belongs_to :package, -> { where(package_type: :pypi) }, inverse_of: :pypi_metadatum

  validates :package, presence: true
end
