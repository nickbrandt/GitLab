# frozen_string_literal: true
class Packages::Tag < ApplicationRecord
  belongs_to :package, inverse_of: :tags

  validates :package, :name, presence: true

  TAGS_LIMIT = 200.freeze

  scope :preload_package, -> { preload(:package) }

  def self.for_packages(packages, max_tags_limit = TAGS_LIMIT)
    where(package_id: packages.select(:id))
      .order(updated_at: :desc)
      .limit(max_tags_limit)
  end
end
