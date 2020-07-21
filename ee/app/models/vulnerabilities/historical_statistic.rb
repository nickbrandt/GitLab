# frozen_string_literal: true

module Vulnerabilities
  class HistoricalStatistic < ApplicationRecord
    self.table_name = 'vulnerability_historical_statistics'

    belongs_to :project, optional: false

    validates :date, presence: true
    validates :letter_grade, presence: true
    validates :total, numericality: { greater_than_or_equal_to: 0 }
    validates :critical, numericality: { greater_than_or_equal_to: 0 }
    validates :high, numericality: { greater_than_or_equal_to: 0 }
    validates :medium, numericality: { greater_than_or_equal_to: 0 }
    validates :low, numericality: { greater_than_or_equal_to: 0 }
    validates :unknown, numericality: { greater_than_or_equal_to: 0 }
    validates :info, numericality: { greater_than_or_equal_to: 0 }

    enum letter_grade: Vulnerabilities::Statistic.letter_grades
  end
end
