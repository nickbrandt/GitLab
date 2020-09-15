# frozen_string_literal: true

module SystemNotes
  class IncidentService < ::SystemNotes::BaseService
    # Called when the severity of an Incident has changed
    #
    # Example Note text:
    #
    #   "changed the severity to Medium - S3"
    #
    # Returns the created Note object
    def change_incident_severity
      severity = noteable.severity
      severity_label = IssuableSeverity::SEVERITY_LABELS.fetch(severity.to_sym)
      body = "changed the severity to **#{severity_label}**"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'severity'))
    end
  end
end
