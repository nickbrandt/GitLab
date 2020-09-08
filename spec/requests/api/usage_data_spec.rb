# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::UsageData do
  let_it_be(:user) { create(:user) }

  describe 'POST /usage_data/increment_unique_values' do
    let(:endpoint) { '/usage_data/increment_unique_values' }
    let(:known_event) { 'g_compliance_dashboard' }
    let(:unknown_event) { 'unknown' }

    context 'without CSRF token' do
      it 'returns 401 response' do
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(false)

        post api(endpoint), params: { values: [user.id] }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'without CSRF token' do
      before do
        allow(Gitlab::RequestForgeryProtection).to receive(:verified?).and_return(true)
      end

      context 'when name is missing from params' do
        it 'returns bad request' do
          post api(endpoint), params: { values: [user.id] }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'with correct params' do
        it 'returns status ok' do
          post api(endpoint), params: { name: known_event, values: [user.id] }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end

      context 'with unknown event' do
        it 'returns status ok' do
          post api(endpoint), params: { name: unknown_event, values: [user.id] }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end
end
