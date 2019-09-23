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
    attr_reader :pipeline

    def initialize(pipeline, params = { all: true })
      @pipeline = pipeline
      @params = params
    end

    def execute
      job_types = all_secure_jobs
      job_types = by_specific_job_type(job_types, :sast)
      job_types = by_specific_job_type(job_types, :dast)
      job_types = by_specific_job_type(job_types, :dependency_scanning)
      job_types = by_specific_job_type(job_types, :container_scanning)

      return [] if job_types.empty?

      Feature.enabled?(:ci_build_metadata_config) ? find_jobs(job_types) : find_jobs_legacy(job_types)
    end

    def all_secure_jobs
      if @params[:all]
        return [:sast, :dast, :dependency_scanning, :container_scanning]
      end

      []
    end

    def by_specific_job_type(job_types, job_type)
      if @params[job_type]
        return job_types + [job_type]
      end

      job_types
    end

    def find_jobs(job_types)
      @pipeline.builds.with_secure_reports(job_types)
    end

    def find_jobs_legacy(job_types)
      query = @pipeline.builds.with_secure_report_legacy(job_types.first)

      jobs = job_types.drop(1).reduce(query) do |qry, job_type|
        qry.or(@pipeline.builds.with_secure_report_legacy(job_type))
      end

      jobs.select do |job|
        job_types.find { |job_type| job.options.dig(:artifacts, :reports, job_type) }
      end
    end
  end
end
