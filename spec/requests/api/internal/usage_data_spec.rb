# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Internal::UsageData do
  let_it_be(:user) { create(:user) }
  let(:secret_token) { Gitlab::Shell.secret_token }

  describe 'POST /usage_data/increment_unique_values' do
    let(:endpoint) { '/internal/usage_data/increment_unique_values' }
    let(:known_event) { 'g_compliance_dashboard' }
    let(:unknown_event) { 'unknown' }

    context 'when no credentials are provided' do
      it 'returns 401 error' do
        post api(endpoint), params: { name: known_event, values: [user.id] }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when name is missing from params' do
      it 'returns bad request' do
        post api(endpoint, user), params: { secret_token: secret_token }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with correct params' do
      it 'returns status ok' do
        post api(endpoint, user), params: { secret_token: secret_token, name: known_event, values: [user.id] }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with unknown event' do
      it 'returns status ok' do
        post api(endpoint, user), params: { secret_token: secret_token, name: unknown_event, values: [user.id] }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end
end
