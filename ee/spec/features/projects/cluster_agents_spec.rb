# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ClusterAgents', :js do
  let_it_be(:token) { create(:cluster_agent_token, description: 'feature test token')}

  let(:agent) { token.agent }
  let(:project) { agent.project }
  let(:user) { project.creator }

  before do
    gitlab_sign_in(user)
  end

  context 'non-premium user' do
    before do
      stub_licensed_features(cluster_agents: false)
    end

    context 'when user visits agents index page' do
      before do
        visit project_clusters_path(project)
      end

      it 'does not display agent information', :aggregate_failures do
        expect(page).to have_content('Integrate with a cluster certificate')
        expect(page).not_to have_content('GitLab Agent managed clusters')
      end
    end

    context 'when user visits agents show page' do
      before do
        visit project_cluster_agent_path(project, agent.name)
      end

      it 'displays not found' do
        expect(page).to have_title('Not Found')
        expect(page).to have_content('Page Not Found')
      end
    end
  end

  context 'premium user' do
    before do
      stub_licensed_features(cluster_agents: true)
    end

    context 'when user does not have any agents and visits the index page' do
      let(:empty_project) { create(:project) }

      before do
        empty_project.add_maintainer(user)
        visit project_clusters_path(empty_project)
      end

      it 'displays empty state', :aggregate_failures do
        click_link 'GitLab Agent managed clusters'

        expect(page).to have_button('Integrate with the GitLab Agent')
        expect(page).to have_selector('.empty-state')
      end
    end

    context 'when user has an agent' do
      context 'when visiting the index page' do
        before do
          visit project_clusters_path(project)
        end

        it 'displays a table with agent', :aggregate_failures do
          click_link 'GitLab Agent managed clusters'

          expect(page).to have_content(agent.name)
          expect(page).to have_selector('[data-testid="cluster-agent-list-table"] tbody tr', count: 1)
        end
      end

      context 'when visiting the show page' do
        before do
          visit project_cluster_agent_path(project, agent.name)
        end

        it 'displays agent and token information', :aggregate_failures do
          expect(page).to have_content(agent.name)
          expect(page).to have_content(token.description)
        end
      end
    end
  end
end
