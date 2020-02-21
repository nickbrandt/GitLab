# frozen_string_literal: true

module EE
  module GitlabSchema
    extend ActiveSupport::Concern

    prepended do
      lazy_resolve ::Epics::LazyEpicAggregate, :epic_aggregate
    end
  end
end
