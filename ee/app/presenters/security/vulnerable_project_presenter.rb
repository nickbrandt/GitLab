# frozen_string_literal: true

module Security
  class VulnerableProjectPresenter < ::Gitlab::View::Presenter::Delegated
    SEVERITY_LEVELS = ::Vulnerabilities::Finding::SEVERITY_LEVELS.keys

    presents :project

    def initialize(project)
      super(project, counts_for_project(project))
    end

    private

    def counts_for_project(project)
      SEVERITY_LEVELS.each_with_object({}) do |severity, counts|
        counts["#{severity}_vulnerability_count".to_sym] = ::Vulnerabilities::Finding.batch_count_by_project_and_severity(project.id, severity)
      end
    end
  end
end
