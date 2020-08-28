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
        it_behaves_like 'tracking unique hll events', :show do
          let(:request_params) { { scope: 'projects', search: 'term' } }
          let(:target_id) { 'i_search_advanced' }
        end
      end

      context 'i_search_paid' do
        let(:group) { create(:group) }

        before do
          allow(group).to receive(:feature_available?).with(:elastic_search).and_return(true)
        end

        it_behaves_like 'tracking unique hll events', :show do
          let(:request_params) { { group_id: group.id, scope: 'blobs', search: 'term' } }
          let(:target_id) { 'i_search_paid' }
        end
      end
    end
  end
end
