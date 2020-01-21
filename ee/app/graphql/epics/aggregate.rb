# frozen_string_literal: true

module Epics
  class Aggregate
    include AggregateConstants

    def initialize(values)
      raise NotImplementedError.new('Use either CountAggregate or WeightSumAggregate')
    end

    private

    def sum_objects(state, type)
      matching = @sums.select { |sum| sum.state == state && sum.type == type && sum.facet == facet}
      return 0 if @sums.empty?

      matching.map(&:value).reduce(:+) || 0
    end

    def facet
      raise NotImplementedError.new('Use either CountAggregate or WeightSumAggregate')
    end
  end
end
