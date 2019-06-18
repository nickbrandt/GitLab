# frozen_string_literal: true

require 'spec_helper'

describe 'Analytics' do
  include RSpec::Rails::RequestExampleGroup
  include Warden::Test::Helpers

  let(:user) { create(:user) }

  it "redirects to productivity_analytics" do
    expect(get('/-/analytics')).to redirect_to('/-/analytics/productivity_analytics')
  end

  context ':analytics feature is disabled' do
    before do
      stub_feature_flags(analytics: false)
    end

    it 'redirects to sign_in if user is not authenticated' do
      expect(get('/-/analytics')).to redirect_to('/users/sign_in')
    end

    it 'returns 404 if user is authenticated' do
      login_as(user)

      expect(get('/-/analytics')).to eq(404)
    end
  end
end
