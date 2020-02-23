# frozen_string_literal: true

require 'spec_helper'

describe Epics::Aggregate do
  include_context 'includes EpicAggregate constants'

  context 'when CountAggregate' do
    subject { Epics::CountAggregate.new(sums) }

    describe 'summation' do
      let(:sums) { [] }

      context 'when there are no sum objects' do
        it 'returns 0 for all values', :aggregate_failures do
          expect(subject.opened_issues).to eq 0
          expect(subject.closed_issues).to eq 0
          expect(subject.opened_epics).to eq 0
          expect(subject.closed_epics).to eq 0
        end
      end

      context 'when some sums exist' do
        let(:sums) do
          [
              double(:sum, facet: COUNT_FACET, type: EPIC_TYPE, value: 1, state: OPENED_EPIC_STATE),
              double(:sum, facet: COUNT_FACET, type: EPIC_TYPE, value: 1, state: CLOSED_EPIC_STATE),
              double(:sum, facet: COUNT_FACET, type: ISSUE_TYPE, value: 1, state: OPENED_ISSUE_STATE),
              double(:sum, facet: COUNT_FACET, type: ISSUE_TYPE, value: 1, state: OPENED_ISSUE_STATE),
              double(:sum, facet: WEIGHT_SUM_FACET, type: ISSUE_TYPE, value: 22, state: CLOSED_ISSUE_STATE)
          ]
        end

        it 'returns sums of appropriate values', :aggregate_failures do
          expect(subject.opened_issues).to eq 2
          expect(subject.closed_issues).to eq 0
          expect(subject.opened_epics).to eq 1
          expect(subject.closed_epics).to eq 1
        end
      end
    end
  end

  context 'when WeightSumAggregate' do
    subject { Epics::WeightSumAggregate.new(sums) }

    describe 'summation' do
      let(:sums) { [] }

      context 'when there are no sum objects' do
        it 'returns 0 for all values', :aggregate_failures do
          expect(subject.opened_issues).to eq 0
          expect(subject.closed_issues).to eq 0
        end
      end

      context 'when some sums exist' do
        let(:sums) do
          [
              double(:sum, facet: WEIGHT_SUM_FACET, type: ISSUE_TYPE, value: 1, state: OPENED_ISSUE_STATE),
              double(:sum, facet: WEIGHT_SUM_FACET, type: ISSUE_TYPE, value: 1, state: OPENED_ISSUE_STATE),
              double(:sum, facet: COUNT_FACET, type: ISSUE_TYPE, value: 22, state: CLOSED_ISSUE_STATE)
          ]
        end

        it 'returns sums of appropriate values', :aggregate_failures do
          expect(subject.opened_issues).to eq 2
          expect(subject.closed_issues).to eq 0
        end
      end
    end
  end
end
