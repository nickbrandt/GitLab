# frozen_string_literal: true

# This class represents a software license.
# For use in the License Management feature.
class SoftwareLicense < ApplicationRecord
  include Presentable

  validates :name, presence: true

  scope :ordered, -> { order(:name) }
end
