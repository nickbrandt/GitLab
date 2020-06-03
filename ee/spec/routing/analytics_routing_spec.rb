# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Analytics' do
  include Warden::Test::Helpers

  it 'redirects to sign_in if user is not authenticated' do
    expect(get('/-/analytics')).to route_to('analytics/analytics#index')
  end

  context 'when user is logged in' do
    let(:user) { create(:user) }

    before do
      login_as(user)
    end

    context 'cycle_analytics feature flag is enabled by default' do
      it 'succeeds' do
        expect(Gitlab::Analytics).to receive(:cycle_analytics_enabled?).and_call_original

        expect(get('/-/analytics/value_stream_analytics')).to route_to('analytics/cycle_analytics#show')
      end
    end
  end
end
