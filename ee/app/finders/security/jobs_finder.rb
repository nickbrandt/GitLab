# frozen_string_literal: true

# Security::JobsFinder
#
# Used to find jobs (builds) that are for Secure products, SAST, DAST, Dependency Scanning and Container Scanning.
#
# Arguments:
#   pipeline:              only jobs for the specified pipeline will be found
#   params:
#     all:                 boolean, include jobs for all secure job types
#     sast:                boolean, include jobs for SAST
#     dast:                boolean, include jobs for DAST
#     container_scanning:  boolean, include jobs for Container Scanning
#     dependency_scanning: boolean, include jobs for Dependency Scanning

module Security
  class JobsFinder
    include Gitlab::Utils::StrongMemoize

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
      strong_memoize(:job_types_for_processing) do
        if @params[:all]
          JOB_TYPES
        else
          JOB_TYPES.each_with_object([]) do |job_type, job_types|
            job_types << job_type if @params[job_type]
          end
        end
      end
    end

    def find_jobs(job_types)
      @pipeline.builds.with_secure_reports(job_types)
    end

    def find_jobs_legacy(job_types)
      # first job type is added as a WHERE statement
      query = @pipeline.builds.with_secure_report_legacy(job_types.first)

      # following job types are added as OR statements
      jobs = job_types.drop(1).reduce(query) do |qry, job_type|
        qry.or(@pipeline.builds.with_secure_report_legacy(job_type))
      end

      # the query doesn't guarantee accuracy, so we verify it here
      jobs.select do |job|
        job_types.find { |job_type| job.options.dig(:artifacts, :reports, job_type) }
      end
    end
  end
end
