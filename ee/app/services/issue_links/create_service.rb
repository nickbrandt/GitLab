# frozen_string_literal: true

module IssueLinks
  class CreateService < IssuableLinks::CreateService
    def relate_issuables(referenced_issue)
      attrs = { source: issuable, target: referenced_issue }

      if ::Feature.enabled?(:issue_link_types, issuable.project) && params[:link_type].present?
        attrs[:link_type] = params[:link_type]
      end

      link = IssueLink.create(attrs)

      yield if link.persisted?
    end

    def linkable_issuables(issues)
      @linkable_issuables ||= begin
        issues.select { |issue| can?(current_user, :admin_issue_link, issue) }
      end
    end

    def create_notes(referenced_issue, params)
      SystemNoteService.relate_issue(issuable, referenced_issue, current_user)
      SystemNoteService.relate_issue(referenced_issue, issuable, current_user)
    end

    def previous_related_issuables
      @related_issues ||= issuable.related_issues(current_user).to_a
    end
  end
end
