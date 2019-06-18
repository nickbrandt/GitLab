# frozen_string_literal: true

require 'spec_helper'

describe 'Analytics', :routing do
  include RSpec::Rails::RequestExampleGroup

  it "redirects `/-/analytics` to `/-/analytics/productivity_analytics`" do
    expect(get('/-/analytics')).to redirect_to('/-/analytics/productivity_analytics')
  end

  it 'doesnt redirect if :analytics feature is disabled' do
    stub_feature_flags(analytics: false)

    expect(get('/-/analytics')).not_to redirect_to('/-/analytics/productivity_analytics')
    expect(get('/-/analytics')).to redirect_to('/users/sign_in')
  end
end
