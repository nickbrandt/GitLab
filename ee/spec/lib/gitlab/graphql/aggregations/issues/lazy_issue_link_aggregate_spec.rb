# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Aggregations::Issues::LazyIssueLinkAggregate do
  let(:query_ctx) do
    {}
  end
  let(:issue_id) { 37 }
  let(:blocks_issue_id) { 18 }
  let(:blocking_issue_id) { 38 }

  describe '#initialize' do
    it 'adds the issue_id to lazy state' do
      described_class.new(query_ctx, issue_id)

      expect(query_ctx[:lazy_issue_link_aggregate][:pending_ids]).to match [issue_id]
    end
  end

  describe '#issue_link_aggregate' do
    subject { described_class.new(query_ctx, issue_id) }

    before do
      subject.instance_variable_set(:@lazy_state, fake_state)
    end

    context 'if the record has already been loaded' do
      let(:fake_state) do
        { pending_ids: Set.new, loaded_objects: { issue_id => [] } }
      end

      it 'does not make the query again' do
        expect(IssueLink).not_to receive(:blocked_issues_for_collection)

        subject.issue_link_aggregate
      end
    end

    context 'if the record has not been loaded' do
      let(:other_issue_id) { 39 }
      let(:fake_state) do
        { pending_ids: Set.new([issue_id]), loaded_objects: {} }
      end
      let(:fake_data) do
        [
            double(blocked_issue_id: 1745, count: 1.0),
            nil # nil for unblocked issues
        ]
      end

      before do
        expect(IssueLink).to receive(:blocked_issues_for_collection).and_return(fake_data)
      end

      it 'clears the pending IDs' do
        subject.issue_link_aggregate

        lazy_state = subject.instance_variable_get(:@lazy_state)

        expect(lazy_state[:pending_ids]).to be_empty
      end
    end
  end
end
