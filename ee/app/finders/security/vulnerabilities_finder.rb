# frozen_string_literal: true

# Security::VulnerabilitiesFinder
#
# Used to filter Vulnerability records for Vulnerabilities API
#
# Arguments:
#   vulnerable: any object that has a #vulnerabilities method that returns a collection of `Vulnerability`s
#   filters: optional! a hash with one or more of the following:
#     project_ids: if `vulnerable` includes multiple projects (like a Group), this filter will restrict
#                   the vulnerabilities returned to those in the group's projects that also match these IDs
#     report_types: only return vulnerabilities from these report types
#     severities: only return vulnerabilities with these severities
#     states: only return vulnerabilities in these states

module Security
  class VulnerabilitiesFinder
    include FinderMethods

    def initialize(vulnerable, filters = {})
      @filters = filters
      @vulnerabilities = vulnerable.vulnerabilities
    end

    def execute
      filter_by_projects
      filter_by_report_types
      filter_by_severities
      filter_by_states
      filter_by_scanners

      vulnerabilities
    end

    private

    attr_reader :filters, :vulnerabilities

    def filter_by_projects
      if filters[:project_id].present?
        @vulnerabilities = vulnerabilities.for_projects(filters[:project_id])
      end
    end

    def filter_by_report_types
      if filters[:report_type].present?
        @vulnerabilities = vulnerabilities.with_report_types(filters[:report_type])
      end
    end

    def filter_by_severities
      if filters[:severity].present?
        @vulnerabilities = vulnerabilities.with_severities(filters[:severity])
      end
    end

    def filter_by_states
      if filters[:state].present?
        @vulnerabilities = vulnerabilities.with_states(filters[:state])
      end
    end

    def filter_by_scanners
      if filters[:scanner].present?
        @vulnerabilities = vulnerabilities.with_scanners(filters[:scanner])
      end
    end
  end
end
