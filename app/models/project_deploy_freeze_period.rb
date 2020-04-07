# frozen_string_literal: true

class ProjectDeployFreezePeriod < ApplicationRecord
  belongs_to :project

  validates :freeze_start, presence: true
  validates :freeze_end, presence: true
  validates :timezone, presence: true
end
