# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::UsageData do
  let_it_be(:user) { create(:user) }

  describe 'POST /usage_data/increment_unique_values' do
    let(:endpoint) { '/usage_data/increment_unique_values' }
    let(:known_event) { 'g_compliance_dashboard' }
    let(:unknown_event) { 'unknown' }

    context 'usage_data_api feature not enabled' do
      it 'returns not_found' do
        stub_feature_flags(usage_data_api: false)

        post api(endpoint, user), params: { values: [user.id] }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'without authentication' do
      it 'returns 401 response' do
        post api(endpoint), params: { values: [user.id] }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'with authentication' do
      before do
        stub_feature_flags(usage_data_api: true)
      end

      context 'when name is missing from params' do
        it 'returns bad request' do
          post api(endpoint, user), params: { values: [user.id] }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with correct params' do
        it 'returns status ok' do
          post api(endpoint, user), params: { name: known_event, values: [user.id] }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with unknown event' do
        it 'returns status ok' do
          post api(endpoint, user), params: { name: unknown_event, values: [user.id] }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with 11 elements' do
        it 'returns bad request' do
          post api(endpoint, user), params: { name: known_event, values: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11] }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with value of 37 chars' do
        it 'returns bad request' do
          post api(endpoint, user), params: { name: known_event, values: ['48ee87e2-7da5-4299-a56d-0424d5c5dab1e'] }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end
end
