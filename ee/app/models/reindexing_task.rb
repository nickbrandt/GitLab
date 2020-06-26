# frozen_string_literal: true

class ReindexingTask < ApplicationRecord
  IN_PROGRESS_STAGES = %w(initial indexing final).freeze

  enum stage: {
    initial:  0,
    indexing: 1,
    final:    2,
    success:  3,
    failure:  4
  }

  before_save :set_in_progress_flag

  def self.current
    where(in_progress: true).last
  end

  private

  def set_in_progress_flag
    self.in_progress = IN_PROGRESS_STAGES.include?(stage)
  end
end
