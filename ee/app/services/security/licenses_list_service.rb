# frozen_string_literal: true

module Security
  class LicensesListService
    # @param pipeline [Ci::Pipeline]
    def initialize(pipeline:)
      @pipeline = pipeline
    end

    def execute
      pipeline.license_management_report.licenses
    end

    private

    attr_reader :pipeline
  end
end
