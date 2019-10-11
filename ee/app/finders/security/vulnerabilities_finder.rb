# frozen_string_literal: true

# Security::VulnerabilitiesFinder
#
# Used to filter Vulnerability records for Vulnerabilities API
#
# Arguments:
#   project: a Project to query for Vulnerabilities

module Security
  class VulnerabilitiesFinder
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute
      project.vulnerabilities
    end
  end
end
