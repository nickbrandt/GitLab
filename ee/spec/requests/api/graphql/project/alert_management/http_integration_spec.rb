# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting Alert Management HTTP Integration' do
  include ::Gitlab::Routing
  include GraphqlHelpers

  let_it_be(:payload_example) do
    {
      alert: {
        desc: 'Alert description',
        name: 'Alert name'
      }
    }
  end

  let_it_be(:payload_attribute_mapping) do
    {
      title: { path: %w(alert name), type: 'string' },
      description: { path: %w(alert desc), type: 'string', label: 'Description' }
    }
  end

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project_alerting_setting) { create(:project_alerting_setting, project: project) }
  let_it_be(:integration) do
    create(
      :alert_management_http_integration,
      project: project,
      payload_example: payload_example,
      payload_attribute_mapping: payload_attribute_mapping
    )
  end

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

  context 'with project permissions' do
    before do
      project.add_maintainer(current_user)
      post_graphql(query, current_user: current_user)
    end

    context 'with existing HTTP integration' do
      it_behaves_like 'a working graphql query'

      it 'returns the correct properties of the integration' do
        integration_response = graphql_data.dig('project', 'alertManagementHttpIntegration')

        expect(integration_response).to include(
          'id' => GitlabSchema.id_from_object(integration).to_s,
          'type' => 'HTTP',
          'name' => integration.name,
          'active' => integration.active,
          'token' => integration.token,
          'url' => integration.url,
          'apiUrl' => nil,
          'payloadExample' => payload_example.to_json,
          'payloadAttributeMappings' => [
            {
              'fieldName' => 'TITLE',
              'label' => nil,
              'path' => %w(alert name),
              'type' => 'STRING'
            },
            {
              'fieldName' => 'DESCRIPTION',
              'label' => 'Description',
              'path' => %w(alert desc),
              'type' => 'STRING'
            }
          ],
          'payloadAlertFields' => [
            {
              'label' => 'Name',
              'path' => %w(alert name),
              'type' => 'STRING'
            },
            {
              'label' => 'Desc',
              'path' => %w(alert desc),
              'type' => 'STRING'
            }
          ]
        )
      end
    end
  end
end
