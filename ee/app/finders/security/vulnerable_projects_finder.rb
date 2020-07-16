# frozen_string_literal: true

module Security
  class VulnerableProjectsFinder
    PROJECTS_LIMIT = 5000

    def initialize(projects)
      @projects = projects
    end

    def execute
      projects.where("EXISTS(?)", vulnerabilities).limit(PROJECTS_LIMIT) # rubocop:disable CodeReuse/ActiveRecord
    end

    private

    attr_reader :projects

    def vulnerabilities
      ::Vulnerabilities::Finding
        .select(1)
        .undismissed
        .scoped_project
    end
  end
end
