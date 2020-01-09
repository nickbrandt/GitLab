# frozen_string_literal: true

class SentryIssuesFinder
  def initialize(project, current_user = nil)
    @project = project
    @current_user = current_user
  end

  def find_by_identifier(identifier)
    return unless Ability.allowed?(@current_user, :read_sentry_issue, @project)

    sentry_issue = SentryIssue.for_identifier(identifier).first

    return unless sentry_issue && sentry_issue.issue.project == @project

    sentry_issue
  end
end
