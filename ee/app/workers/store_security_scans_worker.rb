# frozen_string_literal: true

class StoreSecurityScansWorker
  include ApplicationWorker

  queue_namespace :security_scans
  feature_category :static_application_security_testing

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    ::Ci::Build.find_by(id: build_id).try do |build|
      break if build.job_artifacts.security_reports.empty?

      Security::StoreScansService.new(build).execute
    end
  end
end
