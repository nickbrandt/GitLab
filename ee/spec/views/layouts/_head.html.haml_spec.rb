require 'spec_helper'

describe 'layouts/_head' do
  before do
    allow(view).to receive(:current_application_settings).and_return(Gitlab::CurrentSettings.current_application_settings)
  end

  context 'when an asset_host is set and snowplow url is set' do
    let(:asset_host) { 'http://test.host' }

    before do
      allow(ActionController::Base).to receive(:asset_host).and_return(asset_host)
      allow(Gitlab::CurrentSettings).to receive(:snowplow_enabled?).and_return(true)
      allow(Gitlab::CurrentSettings).to receive(:snowplow_collector_uri).and_return('www.snow.plow')
    end

    it 'add a snowplow script tag with asset host' do
      render
      expect(rendered).to match('http://test.host/assets/snowplow/')
      expect(rendered).to match('window.snowplow')
      expect(rendered).to match('www.snow.plow')
    end
  end
end
