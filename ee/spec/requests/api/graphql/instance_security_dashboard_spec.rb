# frozen_string_literal: true

require 'spec_helper'

describe 'Query.instanceSecurityDashboard.projects' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:other_project) { create(:project) }
  let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }

  let(:current_user) { user }

  before do
    project.add_developer(user)
    other_project.add_developer(user)

    stub_licensed_features(security_dashboard: true)
  end

  let(:fields) do
    <<~QUERY
    nodes {
      id
    }
    QUERY
  end

  let(:query) do
    graphql_query_for('instanceSecurityDashboard', nil, query_graphql_field('projects', {}, fields))
  end

  subject(:projects) { graphql_data.dig('instanceSecurityDashboard', 'projects', 'nodes') }

  context 'with logged in user' do
    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end

      it 'finds only projects that were added to instance security dashboard' do
        expect(projects).to eq([{ "id" => GitlabSchema.id_from_object(project).to_s }])
      end
    end
  end

  context 'with no user' do
    let(:current_user) { nil }

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: current_user)
      end

      it { is_expected.to be_nil }
    end
  end
end
