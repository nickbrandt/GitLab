# frozen_string_literal: true

# Security::JobsFinder
#
# Used to find jobs (builds) that are for Secure products, SAST, DAST, Dependency Scanning and Container Scanning.
#
# Arguments:
#   pipeline:              only jobs for the specified pipeline will be found
#   params:
#     all:                 boolean, include jobs for all secure job types. Takes precedence over other options.
#     sast:                boolean, include jobs for SAST
#     dast:                boolean, include jobs for DAST
#     container_scanning:  boolean, include jobs for Container Scanning
#     dependency_scanning: boolean, include jobs for Dependency Scanning

module Security
  class JobsFinder
    attr_reader :pipeline

    JOB_TYPES = [:sast, :dast, :dependency_scanning, :container_scanning].freeze

    def initialize(pipeline, params = { all: true })
      @pipeline = pipeline
      @params = params
    end

    def execute
      return [] if job_types_for_processing.empty?

      if Feature.enabled?(:ci_build_metadata_config)
        find_jobs(job_types_for_processing)
      else
        find_jobs_legacy(job_types_for_processing)
      end
    end

    private

    def job_types_for_processing
      return JOB_TYPES if @params[:all]

      JOB_TYPES.select { |job_type| @params[job_type] }
    end

    def find_jobs(job_types)
      @pipeline.builds.with_secure_reports_from_config_options(job_types)
    end

    def find_jobs_legacy(job_types)
      # the query doesn't guarantee accuracy, so we verify it here
      legacy_jobs_query(job_types) do |job|
        job_types.find { |job_type| job.options.dig(:artifacts, :reports, job_type) }
      end
    end

    def legacy_jobs_query(job_types)
      job_types.map do |job_type|
        @pipeline.builds.with_secure_reports_from_options(job_type)
      end.reduce(&:or)
    end
  end
end
