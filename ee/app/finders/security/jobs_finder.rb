# frozen_string_literal: true

# Security::JobsFinder
#
# Used to find jobs (builds) that are for Secure products, SAST, DAST, Dependency Scanning and Container Scanning.
#
# Arguments:
#   params:
#     pipeline:              required, only jobs for the specified pipeline will be found
#     job_types:             required, array of job types that should be returned, defaults to all job types

module Security
  class JobsFinder
    attr_reader :pipeline

    JOB_TYPES = [:sast, :dast, :dependency_scanning, :container_scanning].freeze

    def initialize(pipeline:, job_types: JOB_TYPES)
      @pipeline = pipeline
      @job_types = job_types
    end

    def execute
      return [] if @job_types.empty?

      if Feature.enabled?(:ci_build_metadata_config)
        find_jobs
      else
        find_jobs_legacy
      end
    end

    private

    def find_jobs
      @pipeline.builds.with_secure_reports_from_config_options(@job_types)
    end

    def find_jobs_legacy
      # the query doesn't guarantee accuracy, so we verify it here
      legacy_jobs_query.select do |job|
        @job_types.find { |job_type| job.options.dig(:artifacts, :reports, job_type) }
      end
    end

    def legacy_jobs_query
      @job_types.map do |job_type|
        @pipeline.builds.with_secure_reports_from_options(job_type)
      end.reduce(&:or)
    end
  end
end
