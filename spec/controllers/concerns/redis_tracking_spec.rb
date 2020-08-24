# frozen_string_literal: true

require "spec_helper"

RSpec.describe RedisTracking do
  let(:event_name) { 'g_compliance_dashboard' }
  let(:feature) { 'g_compliance_dashboard_feature' }
  let(:user) { create(:user) }
  let(:visitor_id) { 'b77218e4-eeb1-4e41-ba0e-c1354ea49f7a' }

  let(:controller_class) do
    Class.new do
      include RedisTracking
    end
  end

  let(:controller) { controller_class.new }

  before do
    allow(controller).to receive(:current_user).and_return(:user)
  end

  describe '.track_unique_redis_hll_event' do
    it 'does not track event if feature flag disabled' do
      stub_feature_flags(feature => false)
      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

      controller.track_unique_redis_hll_event(event_name, feature)
    end

    it 'does not track the event when usage ping is disabled' do
      stub_feature_flags(feature => true)
      allow(Gitlab::CurrentSettings).to receive(:usage_ping_enabled?).and_return(false)
      allow(controller).to receive(:cookies).and_return({ visitor_id: visitor_id })
      allow(controller).to receive(:current_user).and_return(nil)

      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event).with(visitor_id, event_name)

      controller.track_unique_redis_hll_event(event_name, feature)
    end

    it 'does not track the event when there is no cookie and user is not logged in' do
      stub_feature_flags(feature => true)
      allow(Gitlab::CurrentSettings).to receive(:usage_ping_enabled?).and_return(true)
      allow(controller).to receive(:cookies).and_return({})
      allow(controller).to receive(:current_user).and_return(nil)

      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event).with(visitor_id, event_name)

      controller.track_unique_redis_hll_event(event_name, feature)
    end

    it 'tracks the event with visitor_id and no user' do
      stub_feature_flags(feature => true)
      allow(Gitlab::CurrentSettings).to receive(:usage_ping_enabled?).and_return(true)
      allow(controller).to receive(:cookies).and_return({ visitor_id: visitor_id })
      allow(controller).to receive(:current_user).and_return(nil)

      expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(visitor_id, event_name)

      controller.track_unique_redis_hll_event(event_name, feature)
    end

    it 'tracks the event with visitor_id and user' do
      stub_feature_flags(feature => true)
      allow(Gitlab::CurrentSettings).to receive(:usage_ping_enabled?).and_return(true)
      allow(controller).to receive(:cookies).and_return({ visitor_id: visitor_id })
      allow(controller).to receive(:current_user).and_return(:user)

      expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(visitor_id, event_name)

      controller.track_unique_redis_hll_event(event_name, feature)
    end
  end
end
