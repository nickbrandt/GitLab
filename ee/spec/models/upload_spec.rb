# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Upload do
  include EE::GeoHelpers

  describe '#destroy' do
    subject { create(:upload, checksum: '8710d2c16809c79fee211a9693b64038a8aae99561bc86ce98a9b46b45677fe4') }

    context 'when running in a Geo primary node' do
      let_it_be(:primary) { create(:geo_node, :primary) }
      let_it_be(:secondary) { create(:geo_node) }

      it 'logs an event to the Geo event log' do
        stub_current_geo_node(primary)

        expect { subject.destroy }.to change(Geo::UploadDeletedEvent, :count).by(1)
      end
    end
  end
end
