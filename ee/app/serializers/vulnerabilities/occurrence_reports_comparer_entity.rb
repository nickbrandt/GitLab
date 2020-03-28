# frozen_string_literal: true

class Vulnerabilities::OccurrenceReportsComparerEntity < Grape::Entity
  expose :base_report_created_at
  expose :base_report_out_of_date
  expose :head_report_created_at
  expose :added, using: Vulnerabilities::OccurrenceEntity
  expose :fixed, using: Vulnerabilities::OccurrenceEntity
  expose :existing, using: Vulnerabilities::OccurrenceEntity
end
