# frozen_string_literal: true

module EE
  module GitlabSchema
    extend ActiveSupport::Concern

    prepended do
      lazy_resolve ::Gitlab::Graphql::Aggregations::Epics::LazyEpicAggregate, :epic_aggregate
      lazy_resolve ::Gitlab::Graphql::Aggregations::Issues::LazyBlockAggregate, :block_aggregate
    end
  end
end
