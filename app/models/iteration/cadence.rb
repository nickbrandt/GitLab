# frozen_string_literal: true

class Iteration::Cadence < ApplicationRecord
  self.table_name = 'iteration_cadences'

  belongs_to :group
  has_many :iterations, foreign_key: :iteration_cadence_id, inverse_of: :iteration_cadence

  validates :title, presence: true
  validates :start_date, presence: true
  validates :group_id, presence: true
  validates :active, presence: true
  validates :automatic, presence: true
end
