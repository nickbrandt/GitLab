# frozen_string_literal: true

require 'spec_helper'

describe 'Analytics' do
  include Warden::Test::Helpers

  it 'redirects to sign_in if user is not authenticated' do
    expect(get('/-/analytics')).to route_to('analytics/analytics#index')
  end

  context 'when user is logged in' do
    let(:user) { create(:user) }

    before do
      stub_feature_flags(group_level_productivity_analytics: false)

      login_as(user)
    end

    context 'productivity_analytics feature flag is enabled by default' do
      it 'succeeds' do
        # make sure we call this method for checking the feature availability
        expect(Gitlab::Analytics).to receive(:productivity_analytics_enabled?).and_call_original

        expect(get('/-/analytics/productivity_analytics')).to route_to('analytics/productivity_analytics#show')
      end
    end

    context 'cycle_analytics feature flag is enabled by default' do
      it 'succeeds' do
        expect(Gitlab::Analytics).to receive(:cycle_analytics_enabled?).and_call_original

        expect(get('/-/analytics/value_stream_analytics')).to route_to('analytics/cycle_analytics#show')
      end
    end

    context 'productivity_analytics feature flag is disabled' do
      before do
        stub_feature_flags(Gitlab::Analytics::PRODUCTIVITY_ANALYTICS_FEATURE_FLAG => false)
      end

      it 'routes to `not_found`' do
        expect(get('/-/analytics/productivity_analytics')).to route_to('application#route_not_found', unmatched_route: '-/analytics/productivity_analytics')
      end
    end
  end
end
