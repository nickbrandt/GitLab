# frozen_string_literal: true

require 'spec_helper'

describe JiraConnect::AppDescriptorController do
  describe '#show' do
    context 'feature disabled' do
      before do
        stub_feature_flags(jira_connect_app: false)
      end

      it 'returns 404' do
        get :show

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'feature enabled' do
      before do
        stub_feature_flags(jira_connect_app: true)
      end

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
end
