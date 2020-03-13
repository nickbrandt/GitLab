# frozen_string_literal: true

class Vulnerabilities::OccurrenceReportsComparerEntity < Grape::Entity
  include RequestAwareEntity

  expose :base_report_created_at
  expose :base_report_out_of_date
  expose :head_report_created_at
  expose :added, using: Vulnerabilities::OccurrenceEntity
  expose :fixed, using: Vulnerabilities::OccurrenceEntity
  expose :existing, using: Vulnerabilities::OccurrenceEntity
  expose :scans do |instance|
    instance.security_scans.map do |scan|
      { 
        'url_count': scan.scanned_resources_count,
        'scan_url': namespace_project_job_url(scan.build.project.namespace, scan.build.project, scan.build)
      }
    end
  end
end
