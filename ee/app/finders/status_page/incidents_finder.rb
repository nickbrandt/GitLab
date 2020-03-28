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
#     # A single issue which includes confidential issues by default)
#     issue = finder.find_by_id(issue_id)
#     # Find a "public only" issue
#     issue = finder.find_by_id(issue_id, include_confidential: false)
#
#     # Most recent 20 non-confidential issues
#     issues = finder.all
#
module StatusPage
  class IncidentsFinder
    MAX_LIMIT = StatusPage::Storage::MAX_RECENT_INCIDENTS

    def initialize(project_id:)
      @project_id = project_id
    end

    def find_by_id(issue_id, include_confidential: true)
      execute(include_confidential: include_confidential)
        .find_by_id(issue_id)
    end

    def all
      execute(sorted: true)
        .limit(MAX_LIMIT) # rubocop: disable CodeReuse/ActiveRecord
    end

    private

    attr_reader :project_id

    def execute(sorted: false, include_confidential: false)
      issues = init_collection
      issues = public_only(issues) unless include_confidential
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
