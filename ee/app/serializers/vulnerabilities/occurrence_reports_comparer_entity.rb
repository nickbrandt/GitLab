# frozen_string_literal: true
      
class Vulnerabilities::OccurrenceReportEntity < Grape::Entity
  expose :report_type, :name, :severity, :confidence, :compare_key, :identifiers, :scanner, :project_fingerprint, :uuid
  expose :metadata_version, :location
end

class Vulnerabilities::OccurrenceReportsComparerEntity < Grape::Entity
  expose :added, using: Vulnerabilities::OccurrenceReportEntity
  expose :fixed, using: Vulnerabilities::OccurrenceReportEntity
  expose :existing, using: Vulnerabilities::OccurrenceReportEntity
end
