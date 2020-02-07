# frozen_string_literal: true

class DailyCodeCoverage < ApplicationRecord
  validates :project_id, presence: true, uniqueness: { scope: [:ref, :name, :date], case_sensitive: false }
  validates :last_pipeline_id, presence: true
  validates :ref, presence: true
  validates :name, presence: true
  validates :coverage, presence: true
  validates :date, presence: true
  validate :newer_pipeline

  private

  def newer_pipeline
    return if new_record?
    return unless last_pipeline_id_changed?

    old_pipeline_id, new_pipeline_id = last_pipeline_id_change
    return if new_pipeline_id > old_pipeline_id

    errors.add(:last_pipeline_id, 'new pipeline ID must be newer than the existing one')
  end
end
