# frozen_string_literal: true

module Gitlab
  module Graphql
    module Aggregations
      module Epics
        class SumTotal
          include Constants

          attr_accessor :sums

          def initialize
            @sums = []
          end

          def add(other_sums)
            sums.concat(other_sums)
          end

          def by_facet(facet)
            return CountAggregate.new(sums) if facet == COUNT

            WeightSumAggregate.new(sums)
          end
        end
      end
    end
  end
end
