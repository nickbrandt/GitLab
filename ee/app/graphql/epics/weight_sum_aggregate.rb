# frozen_string_literal: true

module Epics
  class WeightSumAggregate < Aggregate
    attr_accessor :opened_issues, :closed_issues

    def initialize(sums)
      @sums = sums

      @opened_issues = sum_objects(OPENED_ISSUE_STATE, :issue)
      @closed_issues = sum_objects(CLOSED_ISSUE_STATE, :issue)
    end

    def facet
      WEIGHT_SUM
    end
  end
end
