# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).dora.metrics' do
  include GraphqlHelpers

  let_it_be(:reporter) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:production) { create(:environment, :production, project: project) }

  let(:query) do
    graphql_query_for(:project, { fullPath: project.full_path },
      <<~QUERY
        dora {
          metrics(metric: DEPLOYMENT_FREQUENCY) {
            date
            value
          }
        }
      QUERY
    )
  end

  let(:post_query) { post_graphql(query, current_user: reporter) }
  let(:path_prefix) { %w[project dora metrics] }
  let(:data) { graphql_data.dig(*path_prefix) }

  around do |example|
    travel_to '2021-01-08'.to_time do
      example.run
    end
  end

  before_all do
    project.add_reporter(reporter)

    create(:dora_daily_metrics, deployment_frequency: 3, environment: production, date: '2021-01-01')
    create(:dora_daily_metrics, deployment_frequency: 3, environment: production, date: '2021-01-02')
    create(:dora_daily_metrics, deployment_frequency: 2, environment: production, date: '2021-01-03')
    create(:dora_daily_metrics, deployment_frequency: 2, environment: production, date: '2021-01-04')
    create(:dora_daily_metrics, deployment_frequency: 1, environment: production, date: '2021-01-05')
    create(:dora_daily_metrics, deployment_frequency: 1, environment: production, date: '2021-01-06')
    create(:dora_daily_metrics, deployment_frequency: nil, environment: production, date: '2021-01-07')
  end

  before do
    stub_licensed_features(dora4_analytics: true)
  end

  it 'returns the expected DORA metrics' do
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
