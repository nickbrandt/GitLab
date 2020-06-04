# frozen_string_literal: true

require 'spec_helper'

describe 'query Jira projects' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }

  include_context 'jira projects request context'

  let(:services) { graphql_data_at(:project, :services, :edges) }
  let(:all_jira_projects) { services.first.dig('node', 'allProjects') }
  let(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          services(type: JIRA_SERVICE) {
            edges {
              node {
                ... on JiraService {
                  allProjects {
                    key
                    name
                    projectId
                  }
                }
              }
            }
          }
        }
      }
    )
  end

  context 'when user does not have access' do
    it_behaves_like 'unauthorized users cannot read services'
  end

  context 'when user can access project services' do
    before do
      project.add_maintainer(current_user)
    end

    context 'when jira service enabled and working' do
      before do
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      it 'returns list of all jira projects' do
        project_keys = all_jira_projects.map { |jp| jp['key'] }
        project_names = all_jira_projects.map { |jp| jp['name'] }
        project_ids = all_jira_projects.map { |jp| jp['projectId'] }

        expect(all_jira_projects.size).to eq(2)
        expect(project_keys).to eq(%w(EX ABC))
        expect(project_names).to eq(%w(Example Alphabetical))
        expect(project_ids).to eq([10000, 10001])
      end
    end

    context 'when connection to jira fails' do
      before do
        WebMock.stub_request(:get, 'https://jira.example.com/rest/api/2/serverInfo').to_raise(Errno::ECONNREFUSED)
      end

      it 'returns error', :aggregate_failures do
        post_graphql(query, current_user: current_user)

        expect(all_jira_projects).to be_nil
        expect(graphql_errors).to include(a_hash_including('message' => 'Unable to connect to the Jira instance. Please check your Jira integration configuration.'))
      end
    end

    context 'when jira service is not active' do
      before do
        jira_service.update!(active: false)
      end

      it 'returns error', :aggregate_failures do
        post_graphql(query, current_user: current_user)

        expect(all_jira_projects).to be_nil
        expect(graphql_errors).to include(a_hash_including('message' => 'Jira service not configured.'))
      end
    end
  end
end
