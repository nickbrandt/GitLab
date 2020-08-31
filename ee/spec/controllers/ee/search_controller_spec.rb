# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SearchController do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #show' do
    context 'unique users tracking', :elastic do
      before do
        stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
        allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)
      end

      context 'i_search_advanced' do
        let(:target_id) { 'i_search_advanced' }
        let(:request_params) { { scope: 'projects', search: 'term' } }

        it_behaves_like 'tracking unique hll events', :show

        it 'does not track if feature flag is disabled' do
          stub_feature_flags(search_track_unique_users: false)
          expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event).with(instance_of(String), target_id)

          get :show, params: request_params, format: :html
        end
      end

      # i_search_paid is commented out because of https://gitlab.com/gitlab-org/gitlab/-/issues/243486
      # context 'i_search_paid' do
      #   let(:group) { create(:group) }
      #   let(:request_params) { { group_id: group.id, scope: 'blobs', search: 'term' } }
      #   let(:target_id) { 'i_search_paid' }

      #   before do
      #     allow(group).to receive(:feature_available?).with(:elastic_search).and_return(true)
      #   end

      #   it_behaves_like 'tracking unique hll events', :show

      #   it 'does not track if feature flag is disabled' do
      #     stub_feature_flags(search_track_unique_users: false)
      #     expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event).with(instance_of(String), target_id)

      #     get :show, params: request_params, format: :html
      #   end
      # end
    end
  end
end
