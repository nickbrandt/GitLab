# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Graphql::Aggregations::Epics::LazyEpicAggregate do
  include_context 'includes EpicAggregate constants'

  let(:query_ctx) do
    {}
  end
  let(:epic_id) { 37 }
  let(:epic_iid) { 18 }
  let(:child_epic_id) { 38 }

  describe '#initialize' do
    it 'requires either :weight_sum or :count as a facet', :aggregate_failures do
      expect { described_class.new(query_ctx, epic_id, :nonsense) }.to raise_error(ArgumentError, /Invalid aggregate facet/)
      expect { described_class.new(query_ctx, epic_id, nil) }.to raise_error(ArgumentError, /No aggregate facet/)
      expect { described_class.new(query_ctx, epic_id, "") }.to raise_error(ArgumentError, /No aggregate facet/)
    end

    context 'with valid facets :weight_sum or :count' do
      specify 'as a symbol', :aggregate_failures do
        [:weight_sum, :count].each do |valid_facet|
          described_class.new(query_ctx, epic_id, valid_facet)
        end
      end

      specify 'as a string', :aggregate_failures do
        %w(weight_sum count).each do |valid_facet|
          described_class.new(query_ctx, epic_id, valid_facet)
        end
      end
    end

    it 'adds the epic_id to lazy state' do
      described_class.new(query_ctx, epic_id, :count)

      expect(query_ctx[:lazy_epic_aggregate][:pending_ids]).to match [epic_id]
    end
  end

  describe '#epic_aggregate' do
    let(:single_record) do
      { iid: 6, issues_count: 4, issues_weight_sum: 9, parent_id: nil, issues_state_id: OPENED_ISSUE_STATE, epic_state_id: OPENED_EPIC_STATE }
    end
    let(:epic_info_node) { Gitlab::Graphql::Aggregations::Epics::EpicNode.new(epic_id, [single_record] ) }

    subject { described_class.new(query_ctx, epic_id, :count) }

    before do
      subject.instance_variable_set(:@lazy_state, fake_state)
    end

    context 'if the record has already been loaded' do
      let(:fake_state) do
        { pending_ids: Set.new, tree: { epic_id => epic_info_node } }
      end

      it 'does not make the query again' do
        expect(epic_info_node).to receive(:aggregate_count)
        expect(Gitlab::Graphql::Loaders::BulkEpicAggregateLoader).not_to receive(:new)

        subject.epic_aggregate
      end
    end

    context 'if the record has not been loaded' do
      let(:other_epic_id) { 39 }
      let(:fake_state) do
        { pending_ids: Set.new([epic_id, child_epic_id]), tree: {} }
      end
      let(:fake_data) do
        {
            epic_id => [{ epic_state_id: OPENED_EPIC_STATE, issues_count: 2, issues_weight_sum: 5, parent_id: nil, issues_state_id: OPENED_ISSUE_STATE }],
            child_epic_id => [{ epic_state_id: CLOSED_EPIC_STATE, issues_count: 4, issues_weight_sum: 17, parent_id: epic_id, issues_state_id: CLOSED_ISSUE_STATE }],
            other_epic_id => [{ epic_state_id: OPENED_EPIC_STATE, issues_count: 0, issues_weight_sum: 0, parent_id: nil, issues_state_id: nil }] # represents an epic with no parent and no issues
        }
      end

      before do
        allow(Gitlab::Graphql::Aggregations::Epics::EpicNode).to receive(:aggregate_count).and_call_original
        expect_any_instance_of(Gitlab::Graphql::Loaders::BulkEpicAggregateLoader).to receive(:execute).and_return(fake_data)
      end

      it 'clears the pending IDs' do
        subject.epic_aggregate

        lazy_state = subject.instance_variable_get(:@lazy_state)

        expect(lazy_state[:pending_ids]).to be_empty
      end

      it 'creates the parent-child associations', :aggregate_failures do
        subject.epic_aggregate

        lazy_state = subject.instance_variable_get(:@lazy_state)
        tree = lazy_state[:tree]

        expect(tree[child_epic_id].parent_id).to eq epic_id
        expect(tree[epic_id].child_ids).to match_array([child_epic_id])
      end

      context 'for a parent-child relationship' do
        it 'assembles direct sums', :aggregate_failures do
          subject.epic_aggregate

          lazy_state = subject.instance_variable_get(:@lazy_state)
          tree = lazy_state[:tree]

          expect(tree[epic_id]).to have_direct_total(EPIC_TYPE, COUNT_FACET, CLOSED_EPIC_STATE, 1)
          expect(tree[epic_id]).to have_direct_total(ISSUE_TYPE, WEIGHT_SUM_FACET, OPENED_ISSUE_STATE, 5)
          expect(tree[epic_id]).to have_direct_total(EPIC_TYPE, COUNT_FACET, CLOSED_EPIC_STATE, 1)

          expect(tree[child_epic_id]).to have_direct_total(ISSUE_TYPE, COUNT_FACET, CLOSED_ISSUE_STATE, 4)
          expect(tree[child_epic_id]).to have_direct_total(ISSUE_TYPE, WEIGHT_SUM_FACET, CLOSED_ISSUE_STATE, 17)
        end

        it 'assembles recursive sums for the parent', :aggregate_failures do
          subject.epic_aggregate

          lazy_state = subject.instance_variable_get(:@lazy_state)
          tree = lazy_state[:tree]

          expect(tree[epic_id]).to have_aggregate(tree, ISSUE_TYPE, COUNT_FACET, OPENED_ISSUE_STATE, 2)
          expect(tree[epic_id]).to have_aggregate(tree, ISSUE_TYPE, COUNT_FACET, CLOSED_ISSUE_STATE, 4)
          expect(tree[epic_id]).to have_aggregate(tree, ISSUE_TYPE, WEIGHT_SUM_FACET, OPENED_ISSUE_STATE, 5)
          expect(tree[epic_id]).to have_aggregate(tree, ISSUE_TYPE, WEIGHT_SUM_FACET, CLOSED_ISSUE_STATE, 17)
          expect(tree[epic_id]).to have_aggregate(tree, EPIC_TYPE, COUNT_FACET, CLOSED_EPIC_STATE, 1)
        end
      end

      context 'for a standalone epic with no issues' do
        it 'assembles direct totals', :aggregate_failures do
          subject.epic_aggregate

          lazy_state = subject.instance_variable_get(:@lazy_state)
          tree = lazy_state[:tree]

          expect(tree[other_epic_id].direct_count_totals).to be_empty
          expect(tree[other_epic_id].direct_weight_sum_totals).to be_empty
        end
      end
    end
  end
end
