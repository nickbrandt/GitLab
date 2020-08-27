# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::MilestoneBurnupTimeSeriesResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:milestone) { create(:milestone, project: project, start_date: '2020-01-01', due_date: '2020-01-15') }
  let_it_be(:issues) { create_list(:issue, 2, project: project) }

  before_all do
    create(:resource_milestone_event, issue: issues[0], milestone: milestone, action: :add, created_at: '2020-01-05')
    create(:resource_milestone_event, issue: issues[1], milestone: milestone, action: :add, created_at: '2020-01-10')
  end

  before do
    stub_licensed_features(milestone_charts: true, issue_weights: true)
  end

  subject { resolve(described_class, obj: milestone) }

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(burnup_charts: false)
    end

    it 'returns empty data' do
      expect(subject).to be_empty
    end
  end

  context 'when the feature flag is enabled' do
    before do
      stub_feature_flags(burnup_charts: true)
    end

    it 'returns burnup chart data' do
      expect(subject).to eq([
        {
          date: Date.parse('2020-01-05'),
          scope_count: 1,
          scope_weight: 0,
          completed_count: 0,
          completed_weight: 0
        },
        {
          date: Date.parse('2020-01-10'),
          scope_count: 2,
          scope_weight: 0,
          completed_count: 0,
          completed_weight: 0
        }
      ])
    end

    context 'when the service returns an error' do
      before do
        stub_const('Milestones::BurnupChartService::EVENT_COUNT_LIMIT', 1)
      end

      it 'raises a GraphQL exception' do
        expect { subject }.to raise_error(GraphQL::ExecutionError, 'Burnup chart could not be generated due to too many events')
      end
    end
  end
end
