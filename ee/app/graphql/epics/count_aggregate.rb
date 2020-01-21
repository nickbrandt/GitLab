# frozen_string_literal: true

module Epics
  class CountAggregate < Aggregate
    attr_accessor :opened_issues, :closed_issues, :opened_epics, :closed_epics

    def initialize(sums)
      @sums = sums

      @opened_issues = sum_objects(OPENED_ISSUE_STATE, ISSUE_TYPE)
      @closed_issues = sum_objects(CLOSED_ISSUE_STATE, ISSUE_TYPE)
      @opened_epics = sum_objects(OPENED_EPIC_STATE, EPIC_TYPE)
      @closed_epics = sum_objects(CLOSED_EPIC_STATE, EPIC_TYPE)
    end

    def facet
      COUNT
    end
  end
end
