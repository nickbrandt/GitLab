# frozen_string_literal: true

module Security
  class StaleProjectPresenter < ::Gitlab::View::Presenter::Delegated
    JOB_TYPES = ::Security::JobsFinder::JOB_TYPES

    presents :project

    def initialize(project, latest_security_jobs:)
      super(project, scans_statuses(latest_security_jobs))
    end

    private

    def scans_statuses(jobs)
      {
        unconfigured_scans: unconfigured_scans(jobs),
        out_of_date_scans: out_of_date_scans(jobs)
      }
    end

    def unconfigured_scans(jobs)
      JOB_TYPES.reduce([]) do |acc, type|
        job = jobs.find do |j|
          j.metadata.config_options.dig(:artifacts, :reports).keys.first == type.to_s
        end

        if job.nil?
          acc << type
        end

        acc
      end
    end

    def out_of_date_scans(jobs)
      JOB_TYPES.reduce([]) do |acc, type|
        job = jobs.find do |j|
          j.metadata.config_options.dig(:artifacts, :reports).keys.first == type.to_s
        end

        if job.present? && job.finished_at <= 5.days.ago
          acc << { scan_name: type, days_since_last_scan: (Time.current.to_date - job.finished_at.to_date).to_i }
        end

        acc
      end
    end
  end
end
