# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Aggregations::Epics::EpicNode do
  include_context 'includes EpicAggregate constants'

  let(:epic_id) { 34 }
  let(:epic_iid) { 5 }

  describe '#initialize' do
    let(:fake_data) do
      [
          { iid: epic_iid, epic_state_id: epic_state_id, issues_count: 1, issues_weight_sum: 2, parent_id: parent_id, issues_state_id: OPENED_ISSUE_STATE },
          { iid: epic_iid, epic_state_id: epic_state_id, issues_count: 2, issues_weight_sum: 2, parent_id: parent_id, issues_state_id: CLOSED_ISSUE_STATE }
      ]
    end

    shared_examples 'setting attributes based on the first record' do |attributes|
      let(:parent_id) { attributes[:parent_id] }
      let(:epic_state_id) { attributes[:epic_state_id] }

      it 'sets epic attributes based on the first record' do
        new_node = described_class.new(epic_id, fake_data)

        expect(new_node.parent_id).to eq parent_id
        expect(new_node.epic_state_id).to eq epic_state_id
      end
    end

    it_behaves_like 'setting attributes based on the first record', { epic_state_id: OPENED_EPIC_STATE, parent_id: nil }
    it_behaves_like 'setting attributes based on the first record', { epic_state_id: CLOSED_EPIC_STATE, parent_id: 2 }
  end

  describe '#assemble_issue_totals' do
    subject { described_class.new(epic_id, fake_data) }

    context 'an epic with no issues' do
      let(:fake_data) do
        [
            { iid: epic_iid, epic_state_id: OPENED_EPIC_STATE, issues_count: 0, issues_weight_sum: 0, parent_id: nil, issues_state_id: nil }
        ]
      end

      it 'does not create any totals' do
        subject.assemble_issue_totals

        expect(subject.direct_totals(COUNT_FACET).count).to eq 0
        expect(subject.direct_totals(WEIGHT_SUM_FACET).count).to eq 0
      end
    end

    context 'an epic with issues' do
      context 'with a nonzero count but a zero weight' do
        let(:fake_data) do
          [
              { iid: epic_iid, epic_state_id: OPENED_EPIC_STATE, issues_count: 1, issues_weight_sum: 0, parent_id: nil, issues_state_id: OPENED_ISSUE_STATE }
          ]
        end

        it 'creates no sums for the weight if the issues have 0 weight' do
          subject.assemble_issue_totals

          expect(subject.direct_totals(COUNT_FACET).count).to eq 1
          expect(subject.direct_totals(WEIGHT_SUM_FACET).count).to eq 0
          expect(subject).to have_direct_total(ISSUE_TYPE, COUNT_FACET, OPENED_ISSUE_STATE, 1)
        end
      end

      context 'with a nonzero count and nonzero weight for a single state' do
        let(:fake_data) do
          [
              { iid: epic_iid, epic_state_id: OPENED_EPIC_STATE, issues_count: 1, issues_weight_sum: 2, parent_id: nil, issues_state_id: OPENED_ISSUE_STATE }
          ]
        end

        it 'creates two sums' do
          subject.assemble_issue_totals

          expect(subject).to have_direct_total(ISSUE_TYPE, COUNT_FACET, OPENED_ISSUE_STATE, 1)
          expect(subject).to have_direct_total(ISSUE_TYPE, WEIGHT_SUM_FACET, OPENED_ISSUE_STATE, 2)
        end
      end

      context 'with a nonzero count and nonzero weight for multiple states' do
        let(:fake_data) do
          [
              { iid: epic_iid, epic_state_id: OPENED_EPIC_STATE, issues_count: 1, issues_weight_sum: 2, parent_id: nil, issues_state_id: OPENED_ISSUE_STATE },
              { iid: epic_iid, epic_state_id: OPENED_EPIC_STATE, issues_count: 3, issues_weight_sum: 5, parent_id: nil, issues_state_id: CLOSED_ISSUE_STATE }
          ]
        end

        it 'creates two sums' do
          subject.assemble_issue_totals

          expect(subject).to have_direct_total(ISSUE_TYPE, COUNT_FACET, OPENED_ISSUE_STATE, 1)
          expect(subject).to have_direct_total(ISSUE_TYPE, WEIGHT_SUM_FACET, OPENED_ISSUE_STATE, 2)
          expect(subject).to have_direct_total(ISSUE_TYPE, COUNT_FACET, CLOSED_ISSUE_STATE, 3)
          expect(subject).to have_direct_total(ISSUE_TYPE, WEIGHT_SUM_FACET, CLOSED_ISSUE_STATE, 5)
        end
      end
    end
  end

  describe '#assemble_epic_totals' do
    subject { described_class.new(epic_id, [{ parent_id: nil, epic_state_id: CLOSED_EPIC_STATE }]) }

    context 'with a child epic' do
      let(:child_epic_id) { 45 }
      let!(:child_epic_node) { described_class.new(child_epic_id, [{ parent_id: epic_id, epic_state_id: CLOSED_EPIC_STATE }]) }

      before do
        subject.children << child_epic_node
      end

      it 'adds up the number of the child epics' do
        subject.assemble_epic_totals

        expect(subject).to have_direct_total(EPIC_TYPE, COUNT_FACET, CLOSED_EPIC_STATE, 1)
      end
    end
  end

  describe '#calculate_recursive_sums' do
    subject { described_class.new(epic_id, [{ parent_id: nil, epic_state_id: CLOSED_EPIC_STATE }]) }

    before do
      allow(subject).to receive(:direct_totals).with(COUNT_FACET).and_return(immediate_count_totals)
      allow(subject).to receive(:direct_totals).with(WEIGHT_SUM_FACET).and_return(immediate_weight_sum_totals)
    end

    shared_examples 'returns calculated totals by facet' do |facet, count|
      it 'returns a calculated_count_total' do
        subject.calculate_recursive_sums(facet, tree)

        expect(subject.calculated_totals(facet).count).to eq count
      end
    end

    context 'an epic with no child epics' do
      let(:tree) do
        { epic_id => subject }
      end

      context 'with no child issues' do
        let(:immediate_count_totals) { [] }
        let(:immediate_weight_sum_totals) { [] }

        it_behaves_like 'returns calculated totals by facet', COUNT_FACET, 0
        it_behaves_like 'returns calculated totals by facet', WEIGHT_SUM_FACET, 0
      end

      context 'with an issue with 0 weight' do
        let(:immediate_count_totals) do
          [Gitlab::Graphql::Aggregations::Epics::EpicNode::Sum.new(COUNT_FACET, CLOSED_EPIC_STATE, ISSUE_TYPE, 1)]
        end
        let(:immediate_weight_sum_totals) { [] }

        it_behaves_like 'returns calculated totals by facet', COUNT_FACET, 1
        it_behaves_like 'returns calculated totals by facet', WEIGHT_SUM_FACET, 0
      end

      context 'with an issue with nonzero weight' do
        let(:immediate_count_totals) do
          [
            Gitlab::Graphql::Aggregations::Epics::EpicNode::Sum.new(COUNT_FACET, CLOSED_EPIC_STATE, ISSUE_TYPE, 1)
          ]
        end
        let(:immediate_weight_sum_totals) do
          [
            Gitlab::Graphql::Aggregations::Epics::EpicNode::Sum.new(WEIGHT_SUM_FACET, CLOSED_EPIC_STATE, ISSUE_TYPE, 2)
          ]
        end

        it_behaves_like 'returns calculated totals by facet', COUNT_FACET, 1
        it_behaves_like 'returns calculated totals by facet', WEIGHT_SUM_FACET, 1
      end
    end

    context 'an epic with child epics' do
      let(:child_epic_id) { 45 }
      let(:tree) do
        { epic_id => subject, child_epic_id => child_epic_node }
      end
      let(:child_epic_node) { described_class.new(child_epic_id, [{ parent_id: epic_id, epic_state_id: CLOSED_EPIC_STATE }]) }
      let(:immediate_count_totals) do
        [ # only one opened epic, the child
          Gitlab::Graphql::Aggregations::Epics::EpicNode::Sum.new(COUNT_FACET, OPENED_EPIC_STATE, EPIC_TYPE, 1)
        ]
      end
      let(:immediate_weight_sum_totals) { [] }

      before do
        subject.children << child_epic_node
        allow(child_epic_node).to receive(:direct_totals).with(COUNT_FACET).and_return(child_count_totals)
        allow(child_epic_node).to receive(:direct_totals).with(WEIGHT_SUM_FACET).and_return(child_weight_sum_totals)
      end

      context 'with a child that has issues of nonzero weight' do
        let(:child_count_totals) do
          [
            Gitlab::Graphql::Aggregations::Epics::EpicNode::Sum.new(COUNT_FACET, OPENED_ISSUE_STATE, ISSUE_TYPE, 1)
          ]
        end
        let(:child_weight_sum_totals) do
          [
            Gitlab::Graphql::Aggregations::Epics::EpicNode::Sum.new(WEIGHT_SUM_FACET, OPENED_ISSUE_STATE, ISSUE_TYPE, 2)
          ]
        end

        it 'returns the correct count total' do
          subject.calculate_recursive_sums(COUNT_FACET, tree)

          expect(subject).to have_calculated_total(ISSUE_TYPE, COUNT_FACET, OPENED_ISSUE_STATE, 1)
        end

        it 'returns the correct weight sum total' do
          subject.calculate_recursive_sums(WEIGHT_SUM_FACET, tree)

          expect(subject).to have_calculated_total(ISSUE_TYPE, WEIGHT_SUM_FACET, OPENED_ISSUE_STATE, 2)
        end
      end
    end
  end
end
