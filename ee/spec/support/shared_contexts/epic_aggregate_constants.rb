# frozen_string_literal: true

shared_context 'includes EpicAggregate constants' do
  EPIC_TYPE = Epics::AggregateConstants::EPIC_TYPE
  ISSUE_TYPE = Epics::AggregateConstants::ISSUE_TYPE

  OPENED_EPIC_STATE = Epics::AggregateConstants::OPENED_EPIC_STATE
  CLOSED_EPIC_STATE = Epics::AggregateConstants::CLOSED_EPIC_STATE
  OPENED_ISSUE_STATE = Epics::AggregateConstants::OPENED_ISSUE_STATE
  CLOSED_ISSUE_STATE = Epics::AggregateConstants::CLOSED_ISSUE_STATE

  WEIGHT_SUM_FACET = Epics::AggregateConstants::WEIGHT_SUM
  COUNT_FACET = Epics::AggregateConstants::COUNT
end
