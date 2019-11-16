# frozen_string_literal: true

require 'spec_helper'

describe Geo::DesignRegistry, :geo do
  let!(:design_registry) { create(:geo_design_registry) }

  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  it_behaves_like 'a Geo registry' do
    let(:registry) { create(:geo_design_registry) }
  end

  describe '#search', :geo_fdw do
    let!(:failed_registry) { create(:geo_design_registry, :sync_failed) }
    let!(:synced_registry) { create(:geo_design_registry, :synced) }

    it 'all the registries' do
      result = described_class.search({})

      expect(result.count).to eq(3)
    end

    it 'finds by state' do
      result = described_class.search({ sync_status: :failed })

      expect(result.count).to eq(1)
      expect(result.first.state).to eq('failed')
    end

    it 'finds by name' do
      project = create(:project, name: 'bla')
      create(:design, project: project)
      create(:geo_design_registry, project: project)

      result = described_class.search({ search: 'bla' })

      expect(result.count).to eq(1)
      expect(result.first.project_id).to eq(project.id)
    end
  end

  describe '#finish_sync!' do
    let(:design_registry) { create(:geo_design_registry, :sync_started) }

    it 'finishes registry record' do
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

    context 'when a design sync was scheduled after the last sync began' do
      before do
        design_registry.update!(
          state: 'pending',
          retry_count: 2,
          retry_at: 1.hour.ago,
          force_to_redownload: true,
          last_sync_failure: 'error',
          missing_on_primary: true
        )

        design_registry.finish_sync!
      end

      it 'does not reset state' do
        expect(design_registry.reload.state).to eq 'pending'
      end

      it 'resets the other sync state fields' do
        expect(design_registry.reload).to have_attributes(
          retry_count: 0,
          retry_at: nil,
          force_to_redownload: false,
          last_sync_failure: nil,
          missing_on_primary: false
        )
      end
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
