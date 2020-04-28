# frozen_string_literal: true

class Vulnerabilities::FindingDiffSerializer < BaseSerializer
  include WithPagination

  entity Vulnerabilities::OccurrenceReportsComparerEntity
end
