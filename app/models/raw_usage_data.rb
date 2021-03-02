# frozen_string_literal: true

class RawUsageData < ApplicationRecord
  validates :payload, presence: true
  validates :recorded_at, presence: true, uniqueness: true

  def update_sent_at!
    self.update_column(:sent_at, Time.current)
  end

  def update_version_usage_data_id!(usage_data_id)
    self.update_column(:version_usage_data_id_value, usage_data_id)
  end
end
