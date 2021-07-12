# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cluster agent registration', :js do
  let_it_be(:project) { create(:project) }
  let_it_be(:current_user) { create(:user, maintainer_projects: [project]) }

  before do
    stub_licensed_features(cluster_agents: true)

    allow(Gitlab::Kas).to receive(:enabled?).and_return(true)
    allow(Gitlab::Kas).to receive(:internal_url).and_return('kas.example.internal')

    allow_next_instance_of(Gitlab::Kas::Client) do |client|
      allow(client).to receive(:list_agent_config_files).and_return([
        double(agent_name: 'example-agent-1', path: '.gitlab/agents/example-agent-1/config.yaml'),
        double(agent_name: 'example-agent-2', path: '.gitlab/agents/example-agent-2/config.yaml')
      ])
    end

    allow(Devise).to receive(:friendly_token).and_return('example-agent-token')

    sign_in(current_user)
    visit project_clusters_path(project)
  end

  it 'allows the user to select an agent to install, and displays the resulting agent token' do
    click_link('GitLab Agent managed clusters')

    click_button('Integrate with the GitLab Agent')
    expect(page).to have_content('Install new Agent')

    click_button('Select an Agent')
    click_button('example-agent-2')
    click_button('Next')

    expect(page).to have_content('The token value will not be shown again after you close this window.')
    expect(page).to have_content('example-agent-token')
    expect(page).to have_content('docker run --pull=always --rm')

    click_button('Done')
    expect(page).to have_link('example-agent-2')
    expect(page).to have_no_content('Install new Agent')
  end
end
