# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::DashboardController, 'routing' do
  describe 'root path' do
    include RSpec::Rails::RequestExampleGroup

    it 'to #index' do
      expect(get('/-/security')).to redirect_to(security_dashboard_path)
    end
  end

  it 'to #show' do
    expect(get('/-/security/dashboard')).to route_to('security/dashboard#show')
  end

  it 'to #settings' do
    expect(get('/-/security/dashboard/settings')).to route_to('security/dashboard#settings')
  end
end
