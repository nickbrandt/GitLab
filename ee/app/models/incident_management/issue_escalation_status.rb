# frozen_string_literal: true

module IncidentManagement
  class IssueEscalationStatus < ApplicationRecord
    include ::IncidentManagement::Escalatable

    self.table_name = 'incident_management_issue_escalation_statuses'

    belongs_to :issue

    validates :issue, presence: true, uniqueness: true
    validates :status, presence: true

    alias_attribute :ended_at, :resolved_at
  end
end
