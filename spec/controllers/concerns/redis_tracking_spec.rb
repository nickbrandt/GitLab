# frozen_string_literal: true

require "spec_helper"

RSpec.describe RedisTracking do
  let(:event_name) { 'g_compliance_dashboard' }
  let(:feature) { 'g_compliance_dashboard_feature' }
  let(:user) { create(:user) }

  controller(ApplicationController) do
    include RedisTracking

    skip_before_action

    track_redis_hll_event :index, name: 'i_analytics_dev_ops_score', feature: :g_compliance_dashboard_feature

    def index
      render html: 'index'
    end

    def new
      render html: 'new'
    end
  end

  context 'with feature disabled' do
    it 'does not track the event' do
      stub_feature_flags(feature => false)

      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

      get :index
    end
  end

  context 'with usage ping disabled' do
    it 'does not track the event' do
      stub_feature_flags(feature => true)
      allow(Gitlab::CurrentSettings).to receive(:usage_ping_enabled?).and_return(false)

      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

      get :index
    end
  end

  context 'with feature enabled and usage ping enabled' do
    before do
      stub_feature_flags(feature => true)
      allow(Gitlab::CurrentSettings).to receive(:usage_ping_enabled?).and_return(true)
    end

    context 'when user is logged in' do
      it 'tracks the event' do
        sign_in(user)

        expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)

        get :index
      end
    end

    context 'when user is not logged in and there is no visitor_id' do
      it 'does not tracks the event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        get :index
      end
    end

    context 'for untracked action' do
      it 'does not tracks the event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        get :new
      end
    end
  end
end
