# frozen_string_literal: true

module Security
  class LicensesListService
    # @param pipeline [Ci::Pipeline]
    def initialize(pipeline:)
      @pipeline = pipeline
    end

    def execute
      report.merge_dependencies_info!(dependencies) if dependencies.any?
      report.licenses
    end

    private

    attr_reader :pipeline

    def dependencies
      @dependencies ||= pipeline.dependency_list_report.dependencies_with_licenses
    end

    def report
      @report ||= pipeline.license_scanning_report
    end
  end
end
