# frozen_string_literal: true
#
# Retrieves Issues specifically for the Status Page
# which are rendered as incidents.
#
# Arguments:
#   project_id - The issues are scoped to this project
#
# Examples:
#
#     finder = StatusPage::IncidentsFinder.new(project_id: project_id)
#
#     # A single issue
#     issue, user_notes = finder.find_by_id(issue_id)
#
#     # Most recent 20 issues
#     issues = finder.all
#
module StatusPage
  class IncidentsFinder
    MAX_LIMIT = StatusPage::Storage::MAX_RECENT_INCIDENTS

    def initialize(project_id:)
      @project_id = project_id
    end

    def find_by_id(issue_id)
      execute.find_by_id(issue_id)
    end

    def all
      @sorted = true

      execute
        .limit(MAX_LIMIT) # rubocop: disable CodeReuse/ActiveRecord
    end

    private

    attr_reader :project_id, :with_user_notes, :sorted

    def execute
      issues = init_collection
      issues = public_only(issues)
      issues = by_project(issues)
      issues = reverse_chronological(issues) if sorted
      issues
    end

    def init_collection
      Issue
    end

    def public_only(issues)
      issues.public_only
    end

    def by_project(issues)
      issues.of_projects(project_id)
    end

    def reverse_chronological(issues)
      issues.order_created_desc
    end
  end
end
