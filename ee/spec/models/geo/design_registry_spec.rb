# frozen_string_literal: true

require 'spec_helper'

describe Geo::DesignRegistry, :geo do
  set(:design_registry) { create(:geo_design_registry) }

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  it_behaves_like 'a Geo registry' do
    let(:registry) { create(:geo_design_registry) }
  end

  describe '#finish_sync!' do
    it 'finishes registry record' do
      design_registry = create(:geo_design_registry, :sync_started)

      design_registry.finish_sync!

      expect(design_registry.reload).to have_attributes(
        retry_count: 0,
        retry_at: nil,
        last_sync_failure: nil,
        state: 'synced',
        missing_on_primary: false,
        force_to_redownload: false
      )
    end
  end

  describe '#should_be_redownloaded?' do
    context 'when force_to_redownload is false' do
      it 'returns false' do
        expect(design_registry.should_be_redownloaded?).to be false
      end

      it 'returns true when limit is exceeded' do
        design_registry.retry_count = Geo::DesignRegistry::RETRIES_BEFORE_REDOWNLOAD + 1

        expect(design_registry.should_be_redownloaded?).to be true
      end
    end

    context 'when force_to_redownload is true' do
      it 'resets the state of the sync' do
        design_registry.force_to_redownload = true

        expect(design_registry.should_be_redownloaded?).to be true
      end
    end
  end
end
