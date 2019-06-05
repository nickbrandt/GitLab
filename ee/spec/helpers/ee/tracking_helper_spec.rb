# frozen_string_literal: true

require 'spec_helper'

describe EE::TrackingHelper do
  describe '#tracking_attrs' do
    it 'returns a hash of snowplow data attrs if snowplow is enabled' do
      stub_application_setting(snowplow_enabled: true)

      expect(helper.tracking_attrs('a', 'b', 'c')).to eq(data: { track_label: 'a', track_event: 'b', track_property: 'c' })
    end

    it 'returns an empty hash if snowplow is disabled' do
      stub_application_setting(snowplow_enabled: false)

      expect(helper.tracking_attrs('a', 'b', 'c')).to eq({})
    end
  end
end
