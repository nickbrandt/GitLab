# frozen_string_literal: true

module Vulnerabilities
  class Statistic < ApplicationRecord
    self.table_name = 'vulnerability_statistics'

    belongs_to :project, optional: false

    enum letter_grade: { a: 0, b: 1, c: 2, d: 3, f: 4 }

    validates :total, numericality: { greater_than_or_equal_to: 0 }
    validates :critical, numericality: { greater_than_or_equal_to: 0 }
    validates :high, numericality: { greater_than_or_equal_to: 0 }
    validates :medium, numericality: { greater_than_or_equal_to: 0 }
    validates :low, numericality: { greater_than_or_equal_to: 0 }
    validates :unknown, numericality: { greater_than_or_equal_to: 0 }
    validates :info, numericality: { greater_than_or_equal_to: 0 }

    class << self
      def update_stats_with(vulnerability)
        true
      end
    end
  end
end
