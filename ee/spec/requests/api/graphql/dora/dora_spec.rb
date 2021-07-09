# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.[project|group](fullPath).dora.metrics' do
  include GraphqlHelpers

  let_it_be(:reporter) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project_1) { create(:project, group: group) }
  let_it_be(:project_2) { create(:project, group: group) }
  let_it_be(:project_not_in_group) { create(:project) }
  let_it_be(:production_in_project_1) { create(:environment, :production, project: project_1) }
  let_it_be(:staging_in_project_1) { create(:environment, :staging, project: project_1) }
  let_it_be(:production_in_project_2) { create(:environment, :production, project: project_2) }
  let_it_be(:production_not_in_group) { create(:environment, :production, project: project_not_in_group) }

  let(:post_query) { post_graphql(query, current_user: reporter) }
  let(:data) { graphql_data.dig(*path_prefix) }

  let(:query_body) do
    <<~QUERY
      dora {
        metrics(metric: DEPLOYMENT_FREQUENCY) {
          date
          value
        }
      }
    QUERY
  end

  around do |example|
    travel_to '2021-02-01'.to_time do
      example.run
    end
  end

  before_all do
    group.add_reporter(reporter)

    create(:dora_daily_metrics, deployment_frequency: 3, environment: production_in_project_1, date: '2021-01-01')
    create(:dora_daily_metrics, deployment_frequency: 3, environment: production_in_project_1, date: '2021-01-02')
    create(:dora_daily_metrics, deployment_frequency: 2, environment: production_in_project_1, date: '2021-01-03')
    create(:dora_daily_metrics, deployment_frequency: 2, environment: production_in_project_1, date: '2021-01-04')
    create(:dora_daily_metrics, deployment_frequency: 1, environment: production_in_project_1, date: '2021-01-05')
    create(:dora_daily_metrics, deployment_frequency: 1, environment: production_in_project_1, date: '2021-01-06')
    create(:dora_daily_metrics, deployment_frequency: nil, environment: production_in_project_1, date: '2021-01-07')

    create(:dora_daily_metrics, deployment_frequency: 4, environment: staging_in_project_1, date: '2021-01-08')

    create(:dora_daily_metrics, deployment_frequency: 4, environment: production_in_project_2, date: '2021-01-09')

    create(:dora_daily_metrics, deployment_frequency: 5, environment: production_not_in_group, date: '2021-01-10')
  end

  before do
    stub_licensed_features(dora4_analytics: true)
  end

  context 'when querying for project-level metrics' do
    let(:path_prefix) { %w[project dora metrics] }

    let(:query) do
      graphql_query_for(:project, { fullPath: project_1.full_path }, query_body)
    end

    it 'returns the expected project-level DORA metrics' do
      post_query

      expect(data).to eq(
        [
          { 'value' => 3, 'date' => '2021-01-01' },
          { 'value' => 3, 'date' => '2021-01-02' },
          { 'value' => 2, 'date' => '2021-01-03' },
          { 'value' => 2, 'date' => '2021-01-04' },
          { 'value' => 1, 'date' => '2021-01-05' },
          { 'value' => 1, 'date' => '2021-01-06' },
          { 'value' => nil, 'date' => '2021-01-07' }
        ]
      )
    end
  end

  context 'when querying for group-level metrics' do
    let(:path_prefix) { %w[group dora metrics] }

    let(:query) do
      graphql_query_for(:group, { fullPath: group.full_path }, query_body)
    end

    it 'returns the expected group-level DORA metrics' do
      post_query

      expect(data).to eq(
        [
          { 'value' => 3, 'date' => '2021-01-01' },
          { 'value' => 3, 'date' => '2021-01-02' },
          { 'value' => 2, 'date' => '2021-01-03' },
          { 'value' => 2, 'date' => '2021-01-04' },
          { 'value' => 1, 'date' => '2021-01-05' },
          { 'value' => 1, 'date' => '2021-01-06' },
          { 'value' => nil, 'date' => '2021-01-07' },
          { 'value' => 4, 'date' => '2021-01-09' }
        ]
      )
    end
  end
end
