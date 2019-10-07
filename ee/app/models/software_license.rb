# frozen_string_literal: true

# This class represents a software license.
# For use in the License Management feature.
class SoftwareLicense < ApplicationRecord
  include Presentable

  validates :name, presence: true
  validates :spdx_identifier, length: { maximum: 255 }

  scope :by_name, -> (names) { where(name: names) }
  scope :ordered, -> { order(:name) }
  scope :unknown, -> { where(spdx_identifier: nil) }
  scope :grouped_by_name, -> { group(:name) }

  def self.create_policy_for!(project:, name:, approval_status:)
    project.software_license_policies.create!(
      approval_status: approval_status,
      software_license: safe_find_or_create_by!(name: name)
    )
  end
end
