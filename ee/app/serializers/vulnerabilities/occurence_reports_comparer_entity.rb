# frozen_string_literal: true

class Vulnerabilities::OccurrenceReportsComparerEntity < Grape::Entity
  expose :added, using: Vulnerabilities::OccurrenceEntity
  expose :fixed, using: Vulnerabilities::OccurrenceEntity
  expose :existing, using: Vulnerabilities::OccurrenceEntity
end
