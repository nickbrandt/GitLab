# frozen_string_literal: true

module Security
  # Service for counting the number of scanned resources for
  # an array of report types within a pipeline
  #
  class ScannedResourcesCountingService
    # @param [Ci::Pipeline] pipeline
    # @param Array[Symbol] report_types Summary report types. Valid values are members of Vulnerabilities::Occurrence::REPORT_TYPES
    def initialize(pipeline, report_types)
      @pipeline = pipeline
      @report_types = report_types
    end

    def execute
      @pipeline.builds
        .security_scans_scanned_resources_count(@report_types)
        .transform_keys { |k| Security::Scan.scan_types.key(k) }
        .reverse_merge(no_counts)
    end

    def no_counts
      @report_types.zip([0].cycle).to_h
    end
  end
end
