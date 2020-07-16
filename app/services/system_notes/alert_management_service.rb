# frozen_string_literal: true

module SystemNotes
  class AlertManagementService < ::SystemNotes::BaseService
    # Called when the status of an AlertManagement::Alert has changed
    #
    # alert - AlertManagement::Alert object.
    #
    # Example Note text:
    #
    #   "changed the status to Acknowledged"
    #
    # Returns the created Note object
    def change_alert_status(alert)
      status = AlertManagement::Alert::STATUSES.key(alert.status).to_s.titleize
      body = "changed the status to **#{status}**"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'status'))
    end

    # Called when an issue is created based on an AlertManagement::Alert
    #
    # alert - AlertManagement::Alert object.
    # issue - Issue object.
    #
    # Example Note text:
    #
    #   "created issue #17 for this alert"
    #
    # Returns the created Note object
    def new_alert_issue(alert, issue)
      body = "created issue #{issue.to_reference(project)} for this alert"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'alert_issue_added'))
    end

    # Called when an AlertManagement::Alert is resolved due to the associated alert being closed
    #
    # alert - AlertManagement::Alert object.
    # issue - Issue object.
    #
    # Example Note text:
    #
    #   "resolved this alert due to closing issue #17"
    #
    # Returns the created Note object
    def closed_alert_issue(alert, issue)
      body = "resolved this alert due to closing issue #{issue.to_reference(project)}"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'alert_issue_added'))
    end

  end
end
