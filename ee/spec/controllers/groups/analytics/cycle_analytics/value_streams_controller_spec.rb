# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::CycleAnalytics::ValueStreamsController do
  let_it_be(:user) { create(:user) }
  let_it_be(:group, refind: true) { create(:group) }
  let(:params) { { group_id: group } }
  let!(:value_stream) { create(:cycle_analytics_group_value_stream, group: group) }

  before do
    stub_feature_flags(Gitlab::Analytics::CYCLE_ANALYTICS_FEATURE_FLAG => true)
    stub_licensed_features(cycle_analytics_for_groups: true)

    group.add_maintainer(user)
    sign_in(user)
  end

  describe 'GET #index' do
    it 'succeeds' do
      get :index, params: params

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema('analytics/cycle_analytics/value_streams', dir: 'ee')
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      it 'returns a successful 200 response' do
        expect do
          post :create, params: { group_id: group, value_stream: { name: "busy value stream" } }
        end.to change { Analytics::CycleAnalytics::GroupValueStream.count }.by(1)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'with invalid params' do
      it 'returns an unprocessable entity 422 response' do
        expect do
          post :create, params: { group_id: group, value_stream: { name: '' } }
        end.not_to change { Analytics::CycleAnalytics::GroupValueStream.count }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response["message"]).to eq('Invalid parameters')
      end
    end
  end
end
