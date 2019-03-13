# frozen_string_literal: true

require 'spec_helper'

describe JiraConnect::ConfigurationController do
  describe '#show' do
    context 'feature disabled' do
      before do
        stub_feature_flags(jira_connect_app: false)
      end

      it 'returns 404' do
        get :show

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'feature enabled' do
      before do
        stub_feature_flags(jira_connect_app: true)
      end

      context 'without JWT' do
        it 'returns 403' do
          get :show

          expect(response).to have_gitlab_http_status(403)
        end
      end

      context 'with correct JWT' do
        let(:installation) { create(:jira_connect_installation) }
        let(:qsh) { Atlassian::Jwt.create_query_string_hash('GET', '/configuration') }

        before do
          get :show, params: {
            jwt: Atlassian::Jwt.encode({ iss: installation.client_key, qsh: qsh }, installation.shared_secret)
          }
        end

        it 'returns 200' do
          expect(response).to have_gitlab_http_status(200)
        end

        it 'removes X-Frame-Options to allow rendering in iframe' do
          expect(response.headers['X-Frame-Options']).to be_nil
        end
      end
    end
  end
end
