# frozen_string_literal: true

module FeatureFlagIssues
  class CreateService < IssuableLinks::CreateService
    def previous_related_issuables
      @related_issues ||= issuable.issues.to_a
    end

    def linkable_issuables(issues)
      issues.select { |issue| can?(current_user, :read_issue, issue) }
    end

    def relate_issuables(referenced_issue)
      attrs = { feature_flag_id: issuable.id, issue: referenced_issue }
      ::FeatureFlagIssue.create(attrs)
    end
  end
end
