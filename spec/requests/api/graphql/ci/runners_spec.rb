# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Query.runners' do
  include GraphqlHelpers

  let_it_be(:user) { create_default(:user, :admin) }
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:instance_runner) { create(:ci_runner, :instance, version: 'abc', revision: '123', description: 'Instance runner', ip_address: '127.0.0.1') }
  let_it_be(:project_runner) { create(:ci_runner, :project, active: false, version: 'def', revision: '456', description: 'Project runner', projects: [project], ip_address: '127.0.0.1') }

  let(:runners_graphql_data) { graphql_data['runners'] }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      nodes {
        #{all_graphql_fields_for('CiRunner')}
      }
    QUERY
  end

  let(:query) do
    %(
      query {
        runners(type:#{runner_type},status:#{status}) {
          #{fields}
        }
      }
    )
  end

  before do
    post_graphql(query, current_user: user)
  end

  shared_examples 'a working graphql query returning expected runner' do
    it_behaves_like 'a working graphql query'

    it 'returns expected runner' do
      expect(runners_graphql_data['nodes'].map { |n| n['id']}).to contain_exactly(expected_runner.to_global_id.to_s)
    end
  end

  context 'runner_type is INSTANCE_TYPE and status is ACTIVE' do
    let(:runner_type) { 'INSTANCE_TYPE' }
    let(:status) { 'ACTIVE' }

    let!(:expected_runner) { instance_runner }

    it_behaves_like 'a working graphql query returning expected runner'
  end

  context 'runner_type is PROJECT_TYPE and status is NOT_CONNECTED' do
    let(:runner_type) { 'PROJECT_TYPE' }
    let(:status) { 'NOT_CONNECTED' }

    let!(:expected_runner) { project_runner }

    it_behaves_like 'a working graphql query returning expected runner'
  end
end
