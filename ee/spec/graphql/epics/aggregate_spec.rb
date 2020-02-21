# frozen_string_literal: true

describe Epics::Aggregate do
  let(:epic_type) { described_class::EPIC_TYPE }
  let(:issue_type) { described_class::ISSUE_TYPE }

  let(:opened_epic_state) { described_class::OPENED_EPIC_STATE }
  let(:closed_epic_state) { described_class::CLOSED_EPIC_STATE }
  let(:opened_issue_state) { described_class::OPENED_ISSUE_STATE }
  let(:closed_issue_state) { described_class::CLOSED_ISSUE_STATE }

  let(:weight_sum) { Epics::EpicNode::WEIGHT_SUM }
  let(:count) { Epics::EpicNode::COUNT }

  class Constants
    include ::Epics::AggregateConstants
  end

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
              Epics::Sum.new(facet: :count, type: epic_type, value: 1, state: opened_epic_state),
              Epics::Sum.new(facet: :count, type: epic_type, value: 1, state: closed_epic_state),
              Epics::Sum.new(facet: :count, type: issue_type, value: 1, state: opened_issue_state),
              Epics::Sum.new(facet: :count, type: issue_type, value: 1, state: opened_issue_state),
              Epics::Sum.new(facet: :weight_sum, type: issue_type, value: 22, state: closed_issue_state)
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
              Epics::Sum.new(facet: :weight_sum, type: issue_type, value: 1, state: opened_issue_state),
              Epics::Sum.new(facet: :weight_sum, type: issue_type, value: 1, state: opened_issue_state),
              Epics::Sum.new(facet: :count, type: issue_type, value: 22, state: closed_issue_state)
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
