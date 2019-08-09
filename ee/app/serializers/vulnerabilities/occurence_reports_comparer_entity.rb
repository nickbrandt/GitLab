# frozen_string_literal: true

class Vulnerabilities::OccurrenceReportsComparerEntity < Grape::Entity
  expose :added, using: Vulnerabilities::OccurrenceReportEntity
  expose :fixed, using: Vulnerabilities::OccurrenceReportEntity
  expose :existing, using: Vulnerabilities::OccurrenceReportEntity
end
