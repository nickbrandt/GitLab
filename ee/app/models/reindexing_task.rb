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

  scope :running, -> { where(stage: IN_PROGRESS_STAGES) }

  validate :only_one_running_task_allowed

  def self.current
    running.last
  end

  private

  def only_one_running_task_allowed
    return unless IN_PROGRESS_STAGES.include?(stage)
    return unless another_task_running?

    errors.add(:stage, 'Another task is already running')
  end

  def another_task_running?
    self.class.running
              .id_not_in(self.id)
              .exists?
  end
end
