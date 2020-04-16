# frozen_string_literal: true

class Vulnerabilities::ScanEntity < Grape::Entity
  include RequestAwareEntity

  expose :scanned_resources_count do |scan|
    scan.scanned_resources_count || 0
  end
  expose :job_path do |scan|
    project_job_path(scan.build.project, scan.build)
  end
end
