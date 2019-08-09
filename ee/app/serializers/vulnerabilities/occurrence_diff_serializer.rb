# frozen_string_literal: true

class Vulnerabilities::OccurrenceDiffSerializer < BaseSerializer
  include WithPagination

  entity Vulnerabilities::OccurrenceReportsComparerEntity
end
