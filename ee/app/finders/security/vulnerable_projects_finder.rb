# frozen_string_literal: true

module Security
  class VulnerableProjectsFinder
    def initialize(projects)
      @projects = projects
    end

    def execute
      projects.where("EXISTS(?)", vulnerabilities) # rubocop:disable CodeReuse/ActiveRecord
    end

    private

    attr_reader :projects

    def vulnerabilities
      ::Vulnerabilities::Occurrence
        .select(1)
        .undismissed
        .scoped_project
    end
  end
end
