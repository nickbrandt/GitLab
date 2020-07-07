# frozen_string_literal: true

class Elastic::ReindexingTask < ApplicationRecord
  self.table_name = 'elastic_reindexing_tasks'

  enum state: {
    initial:         0,
    indexing_paused: 1,
    reindexing:      2,
    success:         10, # states less than 10 are considered in_progress
    failure:         11
  }

  before_save :set_in_progress_flag

  def self.current
    where(in_progress: true).last
  end

  def self.running?
    current.present?
  end

  private

  def set_in_progress_flag
    in_progress_states = self.class.states.select { |_, v| v < 10 }.keys

    self.in_progress = in_progress_states.include?(state)
  end
end
