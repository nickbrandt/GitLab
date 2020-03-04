# frozen_string_literal: true

shared_context 'includes EpicAggregate constants' do
  EPIC_TYPE = Gitlab::Graphql::Aggregations::Epics::Constants::EPIC_TYPE
  ISSUE_TYPE = Gitlab::Graphql::Aggregations::Epics::Constants::ISSUE_TYPE

  OPENED_EPIC_STATE = Gitlab::Graphql::Aggregations::Epics::Constants::OPENED_EPIC_STATE
  CLOSED_EPIC_STATE = Gitlab::Graphql::Aggregations::Epics::Constants::CLOSED_EPIC_STATE
  OPENED_ISSUE_STATE = Gitlab::Graphql::Aggregations::Epics::Constants::OPENED_ISSUE_STATE
  CLOSED_ISSUE_STATE = Gitlab::Graphql::Aggregations::Epics::Constants::CLOSED_ISSUE_STATE

  WEIGHT_SUM = Gitlab::Graphql::Aggregations::Epics::Constants::WEIGHT_SUM
  COUNT = Gitlab::Graphql::Aggregations::Epics::Constants::COUNT
end
