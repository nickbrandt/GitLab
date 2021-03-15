# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Alert Management HTTP Integration' do
  include ::Gitlab::Routing
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project_alerting_setting) { create(:project_alerting_setting, project: project) }
  let_it_be(:integration) { create(:alert_management_http_integration, project: project) }
  let_it_be(:another_project_integration) { create(:alert_management_http_integration) }

  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('AlertManagementHttpIntegration')}
    QUERY
  end

  let(:params) { { id: GitlabSchema.id_from_object(integration).to_s } }
  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('alertManagementHttpIntegration', params, fields)
    )
  end

  let(:integration_response) { graphql_data.dig('project', 'alertManagementHttpIntegration') }

  context 'with project permissions' do
    before do
      project.add_maintainer(current_user)
      post_graphql(query, current_user: current_user)
    end

    context 'with existing HTTP integration' do
      it_behaves_like 'a working graphql query'

      it 'returns the correct properties of the integration' do
        expect(integration_response).to include(
          'id' => GitlabSchema.id_from_object(integration).to_s,
          'type' => 'HTTP',
          'name' => integration.name,
          'active' => integration.active,
          'token' => integration.token,
          'url' => integration.url,
          'apiUrl' => nil
        )
      end
    end

    context 'with HTTP integration from another project' do
      let(:params) { { id: GitlabSchema.id_from_object(another_project_integration).to_s } }

      it_behaves_like 'a working graphql query'

      it 'returns blank response' do
        expect(integration_response).to be_nil
      end
    end
  end

  context 'without project permissions' do
    before do
      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'a working graphql query'

    it 'returns blank response' do
      expect(integration_response).to be_nil
    end
  end
end
