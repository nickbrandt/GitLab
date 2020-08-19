# frozen_string_literal: true

module IncidentManagement
  class IncidentData < ApplicationRecord
    belongs_to :project
    belongs_to :issue

    validates :project, :severity, presence: true
    validates :issue, presence: true, uniqueness: true

    enum severity: {
      unknown: 0,
      low: 1,
      medium: 2,
      high: 3,
      critical: 4
    }
  end
end
