# frozen_string_literal: true

module Epics
  class SumTotal
    include AggregateConstants

    attr_accessor :sums

    def initialize
      @sums = []
    end

    def add(other_sums)
      sums.concat(other_sums)
    end

    def by_facet(facet)
      return ::Epics::CountAggregate.new(sums) if facet == COUNT

      ::Epics::WeightSumAggregate.new(sums)
    end
  end
end
