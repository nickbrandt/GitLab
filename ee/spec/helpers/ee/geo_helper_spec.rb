# frozen_string_literal: true
require 'spec_helper'

describe EE::GeoHelper do
  describe '.current_node_human_status' do
    where(:primary, :secondary, :result) do
      [
        [true, false, s_('Geo|primary')],
        [false, true, s_('Geo|secondary')],
        [false, false, s_('Geo|misconfigured')]
      ]
    end

    with_them do
      it 'returns correct results' do
        allow(::Gitlab::Geo).to receive(:primary?).and_return(primary)
        allow(::Gitlab::Geo).to receive(:secondary?).and_return(secondary)

        expect(described_class.current_node_human_status).to eq result
      end
    end
  end
end
