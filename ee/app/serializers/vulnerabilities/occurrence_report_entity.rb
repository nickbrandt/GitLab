# frozen_string_literal: true

class Vulnerabilities::OccurrenceReportEntity < Grape::Entity
  expose :report_type, :name, :severity, :confidence, :compare_key, :identifiers, :scanner, :project_fingerprint, :uuid, :metadata_version, :location
end
