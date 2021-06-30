# frozen_string_literal: true

module IncidentManagement
  class IssueEscalationStatus < ApplicationRecord
    include ::IncidentManagement::Escalatable

    self.table_name = 'incident_management_issue_escalation_statuses'

    belongs_to :issue
    belongs_to :policy, optional: true, class_name: '::IncidentManagement::EscalationPolicy'

    validates :issue, presence: true, uniqueness: true
    validates :status, presence: true

    before_save :retrigger, if: -> { policy_id_changed? && policy_id }

    private

    def retrigger
      self.resolved_at = nil
      self.status = STATUSES[:triggered]
    end
  end
end
