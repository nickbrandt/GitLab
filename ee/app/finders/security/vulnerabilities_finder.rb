# frozen_string_literal: true

# Security::VulnerabilitiesFinder
#
# Used to filter Vulnerability record by set of params for Vulnerabilities API
#
# Arguments:
#   project: a Project to query for Vulnerabilities
#   params:
#     page: Integer
#     per_page: Integer

module Security
  class VulnerabilitiesFinder
    attr_reader :project
    attr_reader :page, :per_page

    def initialize(project, params = {})
      @project = project
      @page = params[:page] || 1
      @per_page = params[:per_page] || 20
    end

    def execute
      project.vulnerabilities.page(page).per(per_page)
    end
  end
end
