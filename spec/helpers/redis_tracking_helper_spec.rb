# frozen_string_literal: true

require "spec_helper"

RSpec.describe RedisTrackingHelper do
  include Devise::Test::ControllerHelpers

  describe '.track_redis_hll_event' do
    let(:event_name) { 'g_compliance_dashboard' }
    let(:current_user) { create(:user) }

    before do
      stub_feature_flags(redis_hll_g_compliance_dashboard: current_user)
    end

    it 'does not track event if feature flag disabled' do
      stub_feature_flags(redis_hll_g_compliance_dashboard: false)
      sign_in(current_user)

      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

      helper.track_unique_redis_hll_event(event_name)
    end

    it 'does not track event if usage ping is disabled' do
      sign_in(current_user)
      expect(Gitlab::CurrentSettings).to receive(:usage_ping_enabled?).and_return(false)

      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

      helper.track_unique_redis_hll_event(event_name)
    end

    it 'does not track event if user is not logged in' do
      expect_any_instance_of(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

      helper.track_unique_redis_hll_event(event_name)
    end

    it 'tracks event if user is logged in' do
      sign_in(current_user)

      expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event)

      helper.track_unique_redis_hll_event(event_name)
    end

    it 'does not tracks event if user is not logged in, but has the cookie already' do
      helper.request.cookies[:visitor_id] = { value: SecureRandom.uuid, expires: 24.months }

      expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

      helper.track_unique_redis_hll_event(event_name)
    end
  end
end
