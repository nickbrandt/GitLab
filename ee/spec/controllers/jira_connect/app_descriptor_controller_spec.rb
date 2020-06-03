# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::AppDescriptorController do
  describe '#show' do
    it 'returns JSON app descriptor' do
      get :show

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to include(
        'baseUrl' => 'https://test.host/-/jira_connect',
        'lifecycle' => {
          'installed' => '/events/installed',
          'uninstalled' => '/events/uninstalled'
        }
      )
    end
  end
end
